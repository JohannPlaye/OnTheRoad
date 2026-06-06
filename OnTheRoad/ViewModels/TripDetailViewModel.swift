import CoreData
import Foundation

final class TripDetailViewModel: ObservableObject {
    let trip: Trip
    private let context = PersistenceController.shared.container.viewContext

    init(trip: Trip) {
        self.trip = trip
    }

    func delete() {
        context.delete(trip)
        try? context.save()
    }

    func csvString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy/MM/dd-HH:mm:ss"
        let start = fmt.string(from: trip.startTime ?? Date())
        let end   = fmt.string(from: trip.endTime   ?? Date())
        let motif = trip.motif ?? ""
        let dist  = frenchNumber(trip.distance,    decimals: 3)
        let sLat  = frenchNumber(trip.startLatitude,  decimals: 6)
        let sLon  = frenchNumber(trip.startLongitude, decimals: 6)
        let eLat  = frenchNumber(trip.endLatitude,    decimals: 6)
        let eLon  = frenchNumber(trip.endLongitude,   decimals: 6)
        let header = "Date départ;Date arrivée;Motif;Distance (km);Lat départ;Long départ;Lat arrivée;Long arrivée"
        let row    = "\(start);\(end);\(motif);\(dist);\(sLat);\(sLon);\(eLat);\(eLon)"
        return "\u{FEFF}\(header)\n\(row)"
    }

    func csvFileURL() -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("trajet-\(trip.id?.uuidString ?? "export").csv")
        try? csvString().write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Private

    private func frenchNumber(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(decimals)f", value).replacingOccurrences(of: ".", with: ",")
    }
}
