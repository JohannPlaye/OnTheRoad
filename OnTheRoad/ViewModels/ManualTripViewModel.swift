import SwiftUI
import MapKit
import CoreData
import Combine

final class ManualTripViewModel: ObservableObject {

    // MARK: - Address search

    @Published var departureQuery   = ""
    @Published var arrivalQuery     = ""
    @Published var departureResults: [MKMapItem] = []
    @Published var arrivalResults:   [MKMapItem] = []
    @Published var selectedDeparture: MKMapItem?
    @Published var selectedArrival:   MKMapItem?
    @Published var searchFocus: SearchFocus = .none

    enum SearchFocus { case none, departure, arrival }

    // MARK: - Route

    @Published var routes: [MKRoute] = []
    @Published var selectedRouteIndex = 0
    @Published var isLoadingRoute = false
    @Published var routeError: String?

    var selectedRoute: MKRoute? {
        guard !routes.isEmpty else { return nil }
        return routes[min(selectedRouteIndex, routes.count - 1)]
    }

    // MARK: - Trip details

    @Published var motif = ""
    @Published var selectedProject: TripProject?
    @Published var tripDate  = Date()          // calendar day
    @Published var timeMode: TimeMode = .departure
    @Published var anchorTime = Date()          // the time the user controls

    enum TimeMode: String, CaseIterable {
        case departure = "Départ"
        case arrival   = "Arrivée"
    }

    // MARK: - Computed datetimes

    var departureDateTime: Date {
        let base = combinedDate(tripDate, anchorTime)
        if timeMode == .departure { return base }
        return base.addingTimeInterval(-(selectedRoute?.expectedTravelTime ?? 0))
    }
    var arrivalDateTime: Date {
        let base = combinedDate(tripDate, anchorTime)
        if timeMode == .arrival { return base }
        return base.addingTimeInterval(selectedRoute?.expectedTravelTime ?? 0)
    }

    // MARK: - Formatted helpers

    var formattedDistance: String {
        guard let r = selectedRoute else { return "--" }
        return String(format: "%.1f km", r.distance / 1000)
    }
    var formattedDuration: String {
        guard let r = selectedRoute else { return "--" }
        let s = Int(r.expectedTravelTime)
        let h = s / 3600; let m = (s % 3600) / 60
        return h > 0 ? "\(h)h\(String(format: "%02d", m))" : "\(m) min"
    }
    var formattedDeparture: String { timeFormatter.string(from: departureDateTime) }
    var formattedArrival:   String { timeFormatter.string(from: arrivalDateTime)   }

    // MARK: - Save state

    @Published var isSaved = false
    var canSave: Bool { selectedRoute != nil && selectedProject != nil }

    // MARK: - Private

    private let context = PersistenceController.shared.container.viewContext
    private var searchWorkItem: DispatchWorkItem?

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()

    // MARK: - Search

    func onDepartureQueryChange(_ query: String) {
        guard !query.isEmpty else { departureResults = []; return }
        scheduleSearch(query: query, focus: .departure)
    }

    func onArrivalQueryChange(_ query: String) {
        guard !query.isEmpty else { arrivalResults = []; return }
        scheduleSearch(query: query, focus: .arrival)
    }

    func selectDeparture(_ item: MKMapItem) {
        selectedDeparture  = item
        departureQuery     = item.name ?? item.placemark.title ?? ""
        departureResults   = []
        searchFocus        = .none
        tryCalculateRoute()
    }

    func selectArrival(_ item: MKMapItem) {
        selectedArrival  = item
        arrivalQuery     = item.name ?? item.placemark.title ?? ""
        arrivalResults   = []
        searchFocus      = .none
        tryCalculateRoute()
    }

    func clearDeparture() {
        selectedDeparture = nil; departureQuery = ""; departureResults = []
        routes = []; routeError = nil
    }

    func clearArrival() {
        selectedArrival = nil; arrivalQuery = ""; arrivalResults = []
        routes = []; routeError = nil
    }

    // MARK: - Route calculation

    func tryCalculateRoute() {
        guard let from = selectedDeparture, let to = selectedArrival else { return }
        isLoadingRoute = true
        routeError     = nil
        routes         = []

        let request          = MKDirections.Request()
        request.source       = from
        request.destination  = to
        request.transportType           = .automobile
        request.requestsAlternateRoutes = true

        MKDirections(request: request).calculate { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isLoadingRoute = false
                if let error {
                    self?.routeError = error.localizedDescription; return
                }
                let sorted = (response?.routes ?? []).sorted { $0.expectedTravelTime < $1.expectedTravelTime }
                self?.routes = sorted
                self?.selectedRouteIndex = 0
            }
        }
    }

    // MARK: - Save

    func save() {
        guard let route = selectedRoute else { return }

        var coords = [CLLocationCoordinate2D](repeating: .init(), count: route.polyline.pointCount)
        route.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: route.polyline.pointCount))

        let start = departureDateTime
        let end   = arrivalDateTime

        let trip = Trip(context: context)
        trip.id              = UUID()
        trip.date            = start
        trip.startTime       = start
        trip.endTime         = end
        trip.distance        = route.distance / 1000
        trip.motif           = motif.trimmingCharacters(in: .whitespaces).isEmpty ? nil : motif
        trip.project         = selectedProject?.rawValue
        trip.gpsPointsData   = coords.encoded()

        if let first = coords.first {
            trip.startLatitude  = first.latitude
            trip.startLongitude = first.longitude
        }
        if let last = coords.last {
            trip.endLatitude  = last.latitude
            trip.endLongitude = last.longitude
        }

        try? context.save()
        isSaved = true
    }

    // MARK: - Private helpers

    private func scheduleSearch(query: String, focus: SearchFocus) {
        searchWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.performSearch(query: query, focus: focus)
        }
        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private func performSearch(query: String, focus: SearchFocus) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        MKLocalSearch(request: request).start { [weak self] response, _ in
            DispatchQueue.main.async {
                let items = response?.mapItems ?? []
                if focus == .departure { self?.departureResults = Array(items.prefix(5)) }
                else                  { self?.arrivalResults   = Array(items.prefix(5)) }
            }
        }
    }

    private func combinedDate(_ date: Date, _ time: Date) -> Date {
        let cal = Calendar.current
        var comps      = cal.dateComponents([.year, .month, .day], from: date)
        let timeComps  = cal.dateComponents([.hour, .minute], from: time)
        comps.hour   = timeComps.hour
        comps.minute = timeComps.minute
        comps.second = 0
        return cal.date(from: comps) ?? date
    }
}
