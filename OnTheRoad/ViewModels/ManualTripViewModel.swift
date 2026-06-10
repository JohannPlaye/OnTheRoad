import SwiftUI
import MapKit
import CoreData
import Combine
import CoreLocation

final class ManualTripViewModel: NSObject, ObservableObject {

    // MARK: - Address search

    @Published var departureQuery   = ""
    @Published var arrivalQuery     = ""
    @Published var departureResults: [MKMapItem] = []
    @Published var arrivalResults:   [MKMapItem] = []
    @Published var selectedDeparture: MKMapItem?
    @Published var selectedArrival:   MKMapItem?

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
    @Published var tripDate  = Date()
    @Published var timeMode: TimeMode = .departure
    @Published var anchorTime = Date()

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

    // MARK: - Current location

    @Published var isLocating = false

    // MARK: - Save state

    @Published var isSaved = false
    var canSave: Bool { selectedRoute != nil && selectedProject != nil }

    // MARK: - Private — retain MKLocalSearch & MKDirections strongly

    private let context = PersistenceController.shared.container.viewContext
    private var departureSearch: MKLocalSearch?
    private var arrivalSearch:   MKLocalSearch?
    private var directions:      MKDirections?
    private var searchWorkItem:  DispatchWorkItem?
    private var oneShotManager:  CLLocationManager?
    private let geocoder = CLGeocoder()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()

    // MARK: - Search

    func onDepartureQueryChange(_ query: String) {
        if query.isEmpty { departureResults = []; return }
        scheduleSearch(query: query, isDeparture: true)
    }

    func onArrivalQueryChange(_ query: String) {
        if query.isEmpty { arrivalResults = []; return }
        scheduleSearch(query: query, isDeparture: false)
    }

    func selectDeparture(_ item: MKMapItem) {
        selectedDeparture = item
        departureQuery    = item.name ?? item.placemark.title ?? ""
        departureResults  = []
        tryCalculateRoute()
    }

    func selectArrival(_ item: MKMapItem) {
        selectedArrival = item
        arrivalQuery    = item.name ?? item.placemark.title ?? ""
        arrivalResults  = []
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

        let request = MKDirections.Request()
        request.source                  = from
        request.destination             = to
        request.transportType           = .automobile
        request.requestsAlternateRoutes = true

        // Retain strongly — inline creation would be deallocated before callback fires
        let dir = MKDirections(request: request)
        directions = dir
        dir.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoadingRoute = false
                if let error {
                    self.routeError = error.localizedDescription; return
                }
                self.routes = (response?.routes ?? [])
                    .sorted { $0.expectedTravelTime < $1.expectedTravelTime }
                self.selectedRouteIndex = 0
            }
        }
    }

    // MARK: - Current location as departure

    /// Demande la position courante (one-shot) et la définit comme point de départ.
    func fetchCurrentLocationAsDeparture() {
        // Si on a déjà une valeur récente dans LocationManager, on l'utilise directement
        if let loc = LocationManager.shared.currentLocation {
            reverseGeocode(loc); return
        }
        isLocating = true
        let mgr = CLLocationManager()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyHundredMeters
        oneShotManager = mgr          // retain
        if mgr.authorizationStatus == .notDetermined {
            mgr.requestWhenInUseAuthorization()
        } else {
            mgr.requestLocation()
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        isLocating = true
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                self?.isLocating = false
                guard let self, let placemark = placemarks?.first else { return }
                let mkPlacemark = MKPlacemark(placemark: placemark)
                let item = MKMapItem(placemark: mkPlacemark)
                item.name = [placemark.name, placemark.locality]
                    .compactMap { $0 }.joined(separator: ", ")
                self.selectedDeparture = item
                self.departureQuery    = item.name ?? placemark.name ?? ""
                self.tryCalculateRoute()
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
        trip.id            = UUID()
        trip.date          = start
        trip.startTime     = start
        trip.endTime       = end
        trip.distance      = route.distance / 1000
        trip.motif         = motif.trimmingCharacters(in: .whitespaces).isEmpty ? nil : motif
        trip.project       = selectedProject?.rawValue
        trip.gpsPointsData = coords.encoded()

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

    // MARK: - Private

    private func scheduleSearch(query: String, isDeparture: Bool) {
        searchWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.performSearch(query: query, isDeparture: isDeparture)
        }
        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    private func performSearch(query: String, isDeparture: Bool) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        // Retain strongly — same reason as MKDirections
        let search = MKLocalSearch(request: request)
        if isDeparture { departureSearch = search }
        else           { arrivalSearch   = search }

        search.start { [weak self] response, _ in
            DispatchQueue.main.async {
                let items = Array((response?.mapItems ?? []).prefix(6))
                if isDeparture { self?.departureResults = items }
                else           { self?.arrivalResults   = items }
            }
        }
    }

    private func combinedDate(_ date: Date, _ time: Date) -> Date {
        let cal = Calendar.current
        var comps     = cal.dateComponents([.year, .month, .day], from: date)
        let timeComps = cal.dateComponents([.hour, .minute], from: time)
        comps.hour = timeComps.hour; comps.minute = timeComps.minute; comps.second = 0
        return cal.date(from: comps) ?? date
    }
}

// MARK: - CLLocationManagerDelegate

extension ManualTripViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        oneShotManager = nil          // libère après usage
        guard let loc = locations.last else { isLocating = false; return }
        reverseGeocode(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { self.isLocating = false }
        oneShotManager = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else {
            DispatchQueue.main.async { self.isLocating = false }
        }
    }
}
