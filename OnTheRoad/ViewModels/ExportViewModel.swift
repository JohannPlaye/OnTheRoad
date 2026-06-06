import CoreData
import Foundation

final class ExportViewModel: ObservableObject {
    @Published var tripCount: Int = 0

    private let context = PersistenceController.shared.container.viewContext

    func load() {
        let request = Trip.fetchRequest()
        tripCount = (try? context.count(for: request)) ?? 0
    }

    func csvFileURL() -> URL? {
        let request = Trip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.startTime, ascending: true)]
        guard let trips = try? context.fetch(request) else { return nil }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy/MM/dd-HH:mm:ss"

        var rows = ["Date départ;Date arrivée;Motif;Distance (km);Lat départ;Long départ;Lat arrivée;Long arrivée"]

        for trip in trips {
            let start = fmt.string(from: trip.startTime ?? Date())
            let end   = fmt.string(from: trip.endTime   ?? Date())
            let motif = trip.motif ?? ""
            let dist  = frenchNumber(trip.distance,       decimals: 3)
            let sLat  = frenchNumber(trip.startLatitude,  decimals: 6)
            let sLon  = frenchNumber(trip.startLongitude, decimals: 6)
            let eLat  = frenchNumber(trip.endLatitude,    decimals: 6)
            let eLon  = frenchNumber(trip.endLongitude,   decimals: 6)
            rows.append("\(start);\(end);\(motif);\(dist);\(sLat);\(sLon);\(eLat);\(eLon)")
        }

        let csv = "\u{FEFF}" + rows.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("OnTheRoad-export.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func frenchNumber(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(decimals)f", value).replacingOccurrences(of: ".", with: ",")
    }
}
