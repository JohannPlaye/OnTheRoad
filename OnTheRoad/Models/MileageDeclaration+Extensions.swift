import Foundation

extension MileageDeclaration {

    /// Display string for the month/year (e.g. "Janvier 2025")
    var formattedMonthYear: String {
        var components = DateComponents()
        components.month = Int(month)
        components.year  = Int(year)
        components.day   = 1
        guard let date = Calendar.current.date(from: components) else { return "-" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "fr_FR")
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date).capitalized
    }

    /// Sortable integer key: year * 100 + month  (e.g. 202501)
    var sortKey: Int { Int(year) * 100 + Int(month) }
}
