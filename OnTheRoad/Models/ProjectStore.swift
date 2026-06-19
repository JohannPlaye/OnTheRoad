import Foundation
import CoreData
import Combine
import SwiftUI

/// Source de vérité pour la liste des projets utilisateur.
/// Persistance via UserDefaults. Renommage avec cascade CoreData sur les Trip existants.
final class ProjectStore: ObservableObject {

    static let shared = ProjectStore()

    @Published private(set) var projects: [String]

    private let key = "user_projects"
    private let context = PersistenceController.shared.container.viewContext

    private init() {
        if let saved = UserDefaults.standard.stringArray(forKey: "user_projects"), !saved.isEmpty {
            projects = saved
        } else {
            // Initialisation avec les projets historiques de l'enum TripProject
            projects = [
                "Arbo cidre",
                "Arbo Vendée",
                "ClimaTerra",
                "Dephy",
                "Efea",
                "Groupe 30 000",
                "Réunion équipe"
            ]
            persist()
        }
    }

    // MARK: - CRUD

    func add(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !projects.contains(trimmed) else { return }
        projects.append(trimmed)
        persist()
    }

    /// Renomme un projet et met à jour tous les Trip CoreData qui l'utilisaient.
    func rename(_ oldName: String, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              trimmed != oldName,
              !projects.contains(trimmed),
              let idx = projects.firstIndex(of: oldName) else { return }

        projects[idx] = trimmed
        persist()

        // Cascade CoreData : met à jour les trajets existants
        let request = Trip.fetchRequest()
        request.predicate = NSPredicate(format: "project == %@", oldName)
        if let trips = try? context.fetch(request), !trips.isEmpty {
            trips.forEach { $0.project = trimmed }
            try? context.save()
        }
    }

    /// Supprime un projet de la liste.
    /// Les Trip existants conservent le nom en l'état (pas de cascade suppression).
    func delete(_ name: String) {
        projects.removeAll { $0 == name }
        persist()
    }

    func delete(at offsets: IndexSet) {
        projects.remove(atOffsets: offsets)
        persist()
    }

    // MARK: - Private

    private func persist() {
        UserDefaults.standard.set(projects, forKey: key)
    }
}
