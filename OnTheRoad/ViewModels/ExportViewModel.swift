import Combine
import CoreData
import Foundation

final class ExportViewModel: ObservableObject {
    @Published var tripCount: Int = 0

    private let context = PersistenceController.shared.container.viewContext

    func load() {
        let request = Trip.fetchRequest()
        tripCount = (try? context.count(for: request)) ?? 0
    }

    func xlsxFileURL() -> URL? {
        let request = Trip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.startTime, ascending: true)]
        guard let trips = try? context.fetch(request) else { return nil }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy/MM/dd-HH:mm:ss"

        let headers = ["Date départ", "Date arrivée", "Motif", "Projet",
                       "Distance (km)", "Lat départ", "Long départ", "Lat arrivée", "Long arrivée"]

        let rows: [[String]] = trips.map { trip in
            [
                fmt.string(from: trip.startTime ?? Date()),
                fmt.string(from: trip.endTime   ?? Date()),
                trip.motif   ?? "",
                trip.project ?? "",
                frenchNumber(trip.distance,       decimals: 3),
                frenchNumber(trip.startLatitude,  decimals: 6),
                frenchNumber(trip.startLongitude, decimals: 6),
                frenchNumber(trip.endLatitude,    decimals: 6),
                frenchNumber(trip.endLongitude,   decimals: 6),
            ]
        }

        return XLSXWriter.fileURL(filename: "OnTheRoad-export.xlsx",
                                  sheetName: "Trajets",
                                  headers: headers,
                                  rows: rows)
    }

    private func frenchNumber(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(decimals)f", value).replacingOccurrences(of: ".", with: ",")
    }
}
