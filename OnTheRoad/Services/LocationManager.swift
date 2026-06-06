import CoreLocation
import Combine
import Foundation

final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    // MARK: - Published state

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var collectedPoints: [CLLocationCoordinate2D] = []
    @Published var currentDistance: Double = 0
    @Published var isTracking: Bool = false
    @Published var isPaused: Bool = false

    // MARK: - Private

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5          // record every 5 m minimum
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public interface

    func requestPermission() {
        manager.requestAlwaysAuthorization()
    }

    func startTracking() {
        collectedPoints = []
        currentDistance = 0
        lastLocation = nil
        isTracking = true
        isPaused = false
        manager.startUpdatingLocation()
    }

    func pauseTracking() {
        isPaused = true
        manager.stopUpdatingLocation()
    }

    func resumeTracking() {
        isPaused = false
        manager.startUpdatingLocation()
    }

    /// Stops tracking and returns the collected data.
    func stopTracking() -> (points: [CLLocationCoordinate2D], distance: Double) {
        manager.stopUpdatingLocation()
        isTracking = false
        isPaused = false
        return (collectedPoints, currentDistance)
    }

    // MARK: - Private helpers

    private func record(_ location: CLLocation) {
        collectedPoints.append(location.coordinate)
        if let last = lastLocation {
            currentDistance += location.distance(from: last) / 1000.0
        }
        lastLocation = location
        currentLocation = location
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isPaused else { return }
        // Filter out inaccurate fixes
        locations
            .filter { $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy <= 50 }
            .forEach { record($0) }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Non-fatal; GPS will resume when signal improves
        print("[LocationManager] error: \(error.localizedDescription)")
    }
}
