import SwiftUI

// TODO: Phase 3 — ExportView complète
struct ExportView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(LinearGradient.appAccent)
                Text("Exporter")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("Bientôt disponible")
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .navigationTitle("Exporter")
        .navigationBarTitleDisplayMode(.inline)
    }
}
