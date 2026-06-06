import CoreData
import CoreLocation

extension Trip {

    // MARK: - Computed properties

    var duration: TimeInterval {
        guard let start = startTime, let end = endTime else { return 0 }
        return end.timeIntervalSince(start)
    }

    var startCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
    }

    var endCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)
    }

    var gpsCoordinates: [CLLocationCoordinate2D] {
        gpsPointsData?.decodedCoordinates() ?? []
    }

    /// Average speed in km/h
    var averageSpeed: Double {
        guard duration > 0 else { return 0 }
        return distance / (duration / 3600)
    }

    // MARK: - Formatted strings

    var formattedDistance: String {
        String(format: "%.2f km", distance)
    }

    var formattedDuration: String {
        let total = Int(duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 { return String(format: "%dh %02dmin", hours, minutes) }
        return String(format: "%dmin %02ds", minutes, seconds)
    }

    var formattedAverageSpeed: String {
        String(format: "%.1f km/h", averageSpeed)
    }

    var formattedStartTime: String {
        startTime?.formatted(date: .omitted, time: .shortened) ?? "-"
    }

    var formattedEndTime: String {
        endTime?.formatted(date: .omitted, time: .shortened) ?? "-"
    }

    var formattedDate: String {
        date?.formatted(date: .abbreviated, time: .omitted) ?? "-"
    }
}
