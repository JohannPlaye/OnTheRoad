import Combine
import CoreData
import Foundation

enum HistoryPeriod: String, CaseIterable, Identifiable {
    case all    = "Tous"
    case today  = "Aujourd'hui"
    case week   = "Semaine"
    case month  = "Mois"
    var id: String { rawValue }
}

final class HistoryViewModel: ObservableObject {
    @Published var period: HistoryPeriod = .month
    @Published var isCustomPeriod: Bool = false
    @Published var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @Published var customEndDate: Date = Date()
    @Published var trips: [Trip] = []

    private let context = PersistenceController.shared.container.viewContext

    func load() {
        let request = Trip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.startTime, ascending: false)]
        request.predicate = isCustomPeriod ? customPredicate() : predicate(for: period)
        trips = (try? context.fetch(request)) ?? []
    }

    func delete(_ trip: Trip) {
        context.delete(trip)
        try? context.save()
        load()
    }

    func xlsxFileURL() -> URL? {
        guard !trips.isEmpty else { return nil }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy/MM/dd-HH:mm:ss"

        let headers = ["Date départ", "Date arrivée", "Motif", "Projet",
                       "Distance (km)", "Lat départ", "Long départ", "Lat arrivée", "Long arrivée"]

        let sorted = trips.sorted { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }
        let rows: [[String]] = sorted.map { trip in
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

        return XLSXWriter.fileURL(filename: "OnTheRoad-historique.xlsx",
                                  sheetName: "Trajets",
                                  headers: headers,
                                  rows: rows)
    }

    private func frenchNumber(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(decimals)f", value).replacingOccurrences(of: ".", with: ",")
    }

    // Trips grouped by calendar day, sorted most-recent first
    var groupedTrips: [(day: Date, trips: [Trip])] {
        let calendar = Calendar.current
        var map: [Date: [Trip]] = [:]
        for trip in trips {
            guard let date = trip.date else { continue }
            let day = calendar.startOfDay(for: date)
            map[day, default: []].append(trip)
        }
        return map.keys.sorted(by: >).map { day in (day: day, trips: map[day]!) }
    }

    // MARK: - Private

    private func customPredicate() -> NSPredicate {
        let start = Calendar.current.startOfDay(for: customStartDate)
        let end   = Calendar.current.date(byAdding: .day, value: 1,
                                          to: Calendar.current.startOfDay(for: customEndDate))!
        return NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
    }

    private func predicate(for period: HistoryPeriod) -> NSPredicate? {
        let calendar = Calendar.current
        let now = Date()
        switch period {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end   = calendar.date(byAdding: .day, value: 1, to: start)!
            return NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        case .week:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return NSPredicate(format: "date >= %@", start as NSDate)
        case .month:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return NSPredicate(format: "date >= %@", start as NSDate)
        case .all:
            return nil
        }
    }
}
