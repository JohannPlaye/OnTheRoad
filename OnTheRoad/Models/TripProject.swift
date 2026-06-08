import Foundation

enum TripProject: String, CaseIterable, Identifiable {
    case arboCidre    = "Arbo cidre"
    case arboVendee   = "Arbo Vendée"
    case climaTerra   = "ClimaTerra"
    case dephy        = "Dephy"
    case efea         = "Efea"
    case groupe30000  = "Groupe 30 000"
    case reunionEquipe = "Réunion équipe"

    var id: String { rawValue }
}
