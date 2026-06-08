import Combine
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

    func saveMotif(_ newMotif: String) {
        trip.motif = newMotif.trimmingCharacters(in: .whitespaces).isEmpty ? nil : newMotif.trimmingCharacters(in: .whitespaces)
        try? context.save()
        objectWillChange.send()
    }

    func saveProject(_ project: TripProject?) {
        trip.project = project?.rawValue
        try? context.save()
        objectWillChange.send()
    }

    func csvFileURL() -> URL? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy/MM/dd-HH:mm:ss"

        let headers = ["Date départ", "Date arrivée", "Motif", "Projet",
                       "Distance (km)", "Lat départ", "Long départ", "Lat arrivée", "Long arrivée"]
        let row: [String] = [
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

        return XLSXWriter.fileURL(filename: "trajet-\(trip.id?.uuidString ?? "export").xlsx",
                                  sheetName: "Trajet",
                                  headers: headers,
                                  rows: [row])
    }

    // MARK: - Private

    private func frenchNumber(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(decimals)f", value).replacingOccurrences(of: ".", with: ",")
    }
}
