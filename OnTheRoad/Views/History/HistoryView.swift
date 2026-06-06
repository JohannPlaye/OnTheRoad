import SwiftUI

// TODO: Phase 2 — HistoryView complète
struct HistoryView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(LinearGradient.appAccent)
                Text("Historique")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("Bientôt disponible")
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .navigationBarHidden(true)
    }
}
