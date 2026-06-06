import CoreData
import Foundation

struct DayStat: Identifiable {
    let id = UUID()
    let date: Date
    let tripCount: Int
    let distance: Double
    let duration: TimeInterval
}

final class StatisticsViewModel: ObservableObject {
    @Published var totalDistance: Double = 0
    @Published var totalTripCount: Int = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var avgDistancePerDay: Double = 0
    @Published var dailyStats: [DayStat] = []

    private let context = PersistenceController.shared.container.viewContext

    func load() {
        let request = Trip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.date, ascending: false)]
        guard let trips = try? context.fetch(request), !trips.isEmpty else {
            totalDistance = 0; totalTripCount = 0; totalDuration = 0
            avgDistancePerDay = 0; dailyStats = []
            return
        }

        totalTripCount = trips.count
        totalDistance  = trips.reduce(0) { $0 + $1.distance }
        totalDuration  = trips.reduce(0) { $0 + $1.duration }

        let calendar = Calendar.current
        var map: [Date: (count: Int, distance: Double, duration: TimeInterval)] = [:]
        for trip in trips {
            guard let date = trip.date else { continue }
            let day = calendar.startOfDay(for: date)
            var s = map[day] ?? (0, 0, 0)
            s.count    += 1
            s.distance += trip.distance
            s.duration += trip.duration
            map[day] = s
        }

        dailyStats = map.keys.sorted(by: >).map { day in
            DayStat(date: day,
                    tripCount: map[day]!.count,
                    distance:  map[day]!.distance,
                    duration:  map[day]!.duration)
        }

        avgDistancePerDay = dailyStats.isEmpty ? 0 : totalDistance / Double(dailyStats.count)
    }

    // MARK: - Formatted helpers

    var formattedTotalDuration: String {
        let t = Int(totalDuration)
        let h = t / 3600
        let m = (t % 3600) / 60
        return h > 0 ? "\(h)h \(m)min" : "\(m)min"
    }
}
