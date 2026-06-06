import CoreLocation
import Foundation

/// Codable wrapper around CLLocationCoordinate2D for CoreData Binary storage
struct GPSPoint: Codable {
    let latitude: Double
    let longitude: Double

    init(_ coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension [CLLocationCoordinate2D] {
    func encoded() -> Data? {
        try? JSONEncoder().encode(map(GPSPoint.init))
    }
}

extension Data {
    func decodedCoordinates() -> [CLLocationCoordinate2D] {
        (try? JSONDecoder().decode([GPSPoint].self, from: self))?.map(\.coordinate) ?? []
    }
}
