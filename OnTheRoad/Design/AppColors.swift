import SwiftUI

extension Color {
    static let appBackground  = Color(red: 10/255,  green: 22/255,  blue: 42/255)
    static let appPurple      = Color(red: 192/255, green: 132/255, blue: 252/255)
    static let appPurpleDark  = Color(red: 168/255, green: 85/255,  blue: 247/255)
    static let appGreen       = Color(red: 74/255,  green: 222/255, blue: 128/255)
    static let appCyan        = Color(red: 34/255,  green: 211/255, blue: 238/255)
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
