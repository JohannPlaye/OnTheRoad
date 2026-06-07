import Combine
import CoreData
import Foundation

enum HistoryPeriod: String, CaseIterable, Identifiable {
    case today  = "Aujourd'hui"
    case week   = "Semaine"
    case month  = "Mois"
    case all    = "Tous"
    var id: String { rawValue }
}

final class HistoryViewModel: ObservableObject {
    @Published var period: HistoryPeriod = .all
    @Published var trips: [Trip] = []

    private let context = PersistenceController.shared.container.viewContext

    func load() {
        let request = Trip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.startTime, ascending: false)]
        request.predicate = predicate(for: period)
        trips = (try? context.fetch(request)) ?? []
    }

    func delete(_ trip: Trip) {
        context.delete(trip)
        try? context.save()
        load()
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
