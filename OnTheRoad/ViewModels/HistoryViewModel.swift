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

    func csvFileURL() -> URL? {
        guard !trips.isEmpty else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy/MM/dd-HH:mm:ss"
        var rows = ["Date départ;Date arrivée;Motif;Distance (km);Lat départ;Long départ;Lat arrivée;Long arrivée"]
        for trip in trips.sorted(by: { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }) {
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
            .appendingPathComponent("OnTheRoad-historique.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
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
