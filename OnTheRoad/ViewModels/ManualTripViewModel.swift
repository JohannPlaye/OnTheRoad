import SwiftUI
import MapKit
import CoreData
import Combine
import CoreLocation

final class ManualTripViewModel: NSObject, ObservableObject {

    // MARK: - Address search (completions pour l'autocomplétion temps réel)

    @Published var departureQuery       = ""
    @Published var arrivalQuery         = ""
    @Published var departureCompletions: [MKLocalSearchCompletion] = []
    @Published var arrivalCompletions:   [MKLocalSearchCompletion] = []
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
    @Published var selectedProject: String?
    @Published var tripDate   = Date()
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

    // MARK: - Private

    private let context = PersistenceController.shared.container.viewContext

    // MKLocalSearchCompleter — l'API d'autocomplétion temps réel (comme Apple Plans)
    private let departureCompleter = MKLocalSearchCompleter()
    private let arrivalCompleter   = MKLocalSearchCompleter()

    // Résolution d'une complétion en MKMapItem
    private var departureSearch: MKLocalSearch?
    private var arrivalSearch:   MKLocalSearch?

    // Calcul d'itinéraire
    private var directions: MKDirections?

    // Géolocalisation one-shot
    private var oneShotManager: CLLocationManager?
    private let geocoder = CLGeocoder()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()

    override init() {
        super.init()
        configureCompleter(departureCompleter)
        configureCompleter(arrivalCompleter)
        departureCompleter.delegate = self
        arrivalCompleter.delegate   = self
    }

    private func configureCompleter(_ c: MKLocalSearchCompleter) {
        c.resultTypes = .address
        // Région autour de la position actuelle si disponible
        if let loc = LocationManager.shared.currentLocation {
            c.region = MKCoordinateRegion(
                center: loc.coordinate,
                latitudinalMeters: 200_000,
                longitudinalMeters: 200_000
            )
        }
    }

    // MARK: - Search (frappe clavier → completer)

    func onDepartureQueryChange(_ query: String) {
        if query.isEmpty { departureCompletions = []; return }
        departureCompleter.queryFragment = query
    }

    func onArrivalQueryChange(_ query: String) {
        if query.isEmpty { arrivalCompletions = []; return }
        arrivalCompleter.queryFragment = query
    }

    // MARK: - Sélection d'une complétion → résolution en MKMapItem

    func selectDeparture(completion: MKLocalSearchCompletion) {
        departureQuery       = completion.title
        departureCompletions = []
        resolveCompletion(completion, isDeparture: true)
    }

    func selectArrival(completion: MKLocalSearchCompletion) {
        arrivalQuery       = completion.title
        arrivalCompletions = []
        resolveCompletion(completion, isDeparture: false)
    }

    private func resolveCompletion(_ completion: MKLocalSearchCompletion, isDeparture: Bool) {
        let request = MKLocalSearch.Request(completion: completion)
        let search  = MKLocalSearch(request: request)
        if isDeparture { departureSearch = search }
        else           { arrivalSearch   = search }

        search.start { [weak self] response, _ in
            DispatchQueue.main.async {
                guard let self, let item = response?.mapItems.first else { return }
                if isDeparture {
                    self.selectedDeparture = item
                } else {
                    self.selectedArrival = item
                }
                self.tryCalculateRoute()
            }
        }
    }

    // MARK: - Clear

    func clearDeparture() {
        selectedDeparture    = nil
        departureQuery       = ""
        departureCompletions = []
        routes = []; routeError = nil
    }

    func clearArrival() {
        selectedArrival    = nil
        arrivalQuery       = ""
        arrivalCompletions = []
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

        let dir = MKDirections(request: request)
        directions = dir
        dir.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoadingRoute = false
                if let error { self.routeError = error.localizedDescription; return }
                self.routes = (response?.routes ?? [])
                    .sorted { $0.expectedTravelTime < $1.expectedTravelTime }
                self.selectedRouteIndex = 0
            }
        }
    }

    // MARK: - Current location as departure

    func fetchCurrentLocationAsDeparture() {
        if let loc = LocationManager.shared.currentLocation {
            reverseGeocode(loc); return
        }
        isLocating = true
        let mgr = CLLocationManager()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyHundredMeters
        oneShotManager = mgr
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
        trip.project       = selectedProject
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

    // MARK: - Helpers

    private func combinedDate(_ date: Date, _ time: Date) -> Date {
        let cal = Calendar.current
        var comps     = cal.dateComponents([.year, .month, .day], from: date)
        let timeComps = cal.dateComponents([.hour, .minute], from: time)
        comps.hour = timeComps.hour; comps.minute = timeComps.minute; comps.second = 0
        return cal.date(from: comps) ?? date
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension ManualTripViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = Array(completer.results.prefix(5))
        DispatchQueue.main.async {
            if completer === self.departureCompleter {
                self.departureCompletions = results
            } else {
                self.arrivalCompletions = results
            }
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Silencieux — l'utilisateur peut continuer à taper
    }
}

// MARK: - CLLocationManagerDelegate

extension ManualTripViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        oneShotManager = nil
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
