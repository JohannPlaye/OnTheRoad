import Combine
import CoreData
import Foundation

final class MileageDeclarationViewModel: ObservableObject {

    // MARK: - Published state

    @Published var declarations: [MileageDeclaration] = []

    // Add sheet
    @Published var showAddSheet       = false
    @Published var newMonth: Int      = Calendar.current.component(.month, from: Date())
    @Published var newYear:  Int      = Calendar.current.component(.year,  from: Date())
    @Published var newKilometers      = ""

    // Edit confirmation
    @Published var editingEntry: MileageDeclaration? = nil
    @Published var editKilometers     = ""
    @Published var showEditConfirm    = false

    // Validation
    @Published var errorMessage: String? = nil

    // MARK: - Private

    private let context = PersistenceController.shared.container.viewContext

    // MARK: - Load

    func load() {
        let request = MileageDeclaration.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MileageDeclaration.year,  ascending: false),
                                   NSSortDescriptor(keyPath: \MileageDeclaration.month, ascending: false)]
        declarations = (try? context.fetch(request)) ?? []
    }

    // MARK: - Helpers

    /// Available months for the "new entry" picker: all months up to current, not yet declared
    var availableMonthYears: [(month: Int, year: Int)] {
        let now     = Date()
        let cal     = Calendar.current
        let curYear = cal.component(.year,  from: now)
        let curMon  = cal.component(.month, from: now)

        let declared = Set(declarations.map { "\($0.year)-\($0.month)" })

        var result: [(month: Int, year: Int)] = []
        // Go back 3 years
        for y in ((curYear - 3)...curYear).reversed() {
            let maxM = (y == curYear) ? curMon : 12
            for m in (1...maxM).reversed() {
                let key = "\(y)-\(m)"
                if !declared.contains(key) {
                    result.append((month: m, year: y))
                }
            }
        }
        return result
    }

    var selectedMonthYearIndex: Int {
        availableMonthYears.firstIndex(where: { $0.month == newMonth && $0.year == newYear }) ?? 0
    }

    func labelFor(month: Int, year: Int) -> String {
        var components = DateComponents()
        components.month = month; components.year = year; components.day = 1
        guard let date = Calendar.current.date(from: components) else { return "-" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "fr_FR")
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date).capitalized
    }

    // MARK: - Add

    func prepareAdd() {
        // Default to first available month/year (most recent not yet declared)
        if let first = availableMonthYears.first {
            newMonth = first.month
            newYear  = first.year
        }
        newKilometers = ""
        errorMessage  = nil
        showAddSheet  = true
    }

    func confirmAdd() {
        guard let km = Double(newKilometers.replacingOccurrences(of: ",", with: ".")),
              km >= 0 else {
            errorMessage = "Kilométrage invalide."
            return
        }
        let entry = MileageDeclaration(context: context)
        entry.id          = UUID()
        entry.month       = Int16(newMonth)
        entry.year        = Int16(newYear)
        entry.kilometers  = km
        entry.createdAt   = Date()
        try? context.save()
        showAddSheet = false
        load()
    }

    // MARK: - Edit

    func startEdit(_ entry: MileageDeclaration) {
        editingEntry   = entry
        editKilometers = String(format: "%.0f", entry.kilometers)
        showEditConfirm = true
    }

    func confirmEdit() {
        guard let entry = editingEntry,
              let km = Double(editKilometers.replacingOccurrences(of: ",", with: ".")),
              km >= 0 else { return }
        entry.kilometers = km
        try? context.save()
        showEditConfirm = false
        editingEntry    = nil
        load()
    }

    // MARK: - Delete

    func delete(_ entry: MileageDeclaration) {
        context.delete(entry)
        try? context.save()
        load()
    }
}
