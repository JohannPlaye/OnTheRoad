import SwiftUI

extension Color {
    static let appBackground  = Color(red: 10/255,  green: 22/255,  blue: 42/255)
    static let appPurple      = Color(red: 192/255, green: 132/255, blue: 252/255)
    static let appPurpleDark  = Color(red: 168/255, green: 85/255,  blue: 247/255)
    static let appGreen       = Color(red: 74/255,  green: 222/255, blue: 128/255)
    static let appCyan        = Color(red: 16/255,  green: 240/255, blue: 160/255)
    static let appGrey        = Color(red: 242/255, green: 242/255, blue: 242/255)
    static let appPink        = Color(red: 240/255, green: 16/255,  blue: 94/255)
    static let appOrange      = Color(red: 240/255, green: 162/255, blue: 16/255)
}

extension LinearGradient {
    static let appAccent = LinearGradient(
        colors: [.appPurple, .appCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let appAccentH = LinearGradient(
        colors: [.appPurple, .appCyan],
        startPoint: .leading,
        endPoint: .trailing
    )
}
