import SwiftUI
import CoreData
import CoreLocation
import Combine

enum TripState {
    case idle, tracking, paused, saving, saved
}

final class TripViewModel: ObservableObject {
    @Published var state: TripState = .idle
    @Published var showSummaryModal = false
    @Published var showFireworks = false
    @Published var motif = ""
    @Published var elapsedSeconds: Int = 0

    let locationManager = LocationManager.shared
    private let context = PersistenceController.shared.container.viewContext

    private var startDate: Date?
    private var endDate: Date?
    private var savedPoints: [CLLocationCoordinate2D] = []
    private var savedDistance: Double = 0
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Trip lifecycle

    func startTrip() {
        startDate = Date()
        elapsedSeconds = 0
        locationManager.startTracking()
        state = .tracking
        startTimer()
    }

    func pauseTrip() {
        locationManager.pauseTracking()
        state = .paused
        timer?.invalidate()
    }

    func resumeTrip() {
        locationManager.resumeTracking()
        state = .tracking
        startTimer()
    }

    func stopTrip() {
        endDate = Date()
        let result = locationManager.stopTracking()
        savedPoints   = result.points
        savedDistance = result.distance
        state = .saving
        timer?.invalidate()
        showSummaryModal = true
    }

    func saveTrip() {
        guard let start = startDate, let end = endDate else { return }

        let trip = Trip(context: context)
        trip.id          = UUID()
        trip.date        = start
        trip.startTime   = start
        trip.endTime     = end
        trip.distance    = savedDistance
        trip.motif       = motif.trimmingCharacters(in: .whitespaces).isEmpty ? nil : motif
        trip.gpsPointsData = savedPoints.encoded()

        if let first = savedPoints.first {
            trip.startLatitude  = first.latitude
            trip.startLongitude = first.longitude
        }
        if let last = savedPoints.last {
            trip.endLatitude  = last.latitude
            trip.endLongitude = last.longitude
        }

        try? context.save()

        showSummaryModal = false

        withAnimation { showFireworks = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { [weak self] in
            withAnimation { self?.showFireworks = false }
            self?.state = .saved
        }
    }

    func discardTrip() {
        showSummaryModal = false
        reset()
        state = .saved  // triggers dismiss in TripView
    }

    // MARK: - Helpers

    var formattedElapsed: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Private

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.startDate else { return }
            self.elapsedSeconds = Int(Date().timeIntervalSince(start))
        }
    }

    private func reset() {
        motif = ""
        elapsedSeconds = 0
        startDate = nil
        endDate = nil
        savedPoints = []
        savedDistance = 0
    }
}
