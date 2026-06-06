import CoreData
import Combine
import Foundation

final class HomeViewModel: ObservableObject {
    @Published var todayTripCount: Int = 0
    @Published var todayDistance: Double = 0

    private let context = PersistenceController.shared.container.viewContext

    func refresh() {
        let request = Trip.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay   = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay   as NSDate
        )
        guard let trips = try? context.fetch(request) else { return }
        todayTripCount = trips.count
        todayDistance  = trips.reduce(0) { $0 + $1.distance }
    }
}
