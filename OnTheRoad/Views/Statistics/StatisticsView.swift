import SwiftUI

// TODO: Phase 3 — StatisticsView complète
struct StatisticsView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(LinearGradient.appAccent)
                Text("Statistiques")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("Bientôt disponible")
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .navigationTitle("Statistiques")
        .navigationBarTitleDisplayMode(.inline)
    }
}
