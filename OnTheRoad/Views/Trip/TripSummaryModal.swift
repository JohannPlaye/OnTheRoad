import SwiftUI

struct TripSummaryModal: View {
    @ObservedObject var vm: TripViewModel
    let onSave: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 24) {
                // Title
                VStack(spacing: 6) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 36))
                        .foregroundColor(.appGreen)
                    Text("Trajet terminé !")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }

                // Stats row
                HStack(spacing: 12) {
                    miniStat(
                        icon: "road.lanes",
                        value: String(format: "%.2f km", vm.locationManager.currentDistance),
                        label: "Distance"
                    )
                    miniStat(
                        icon: "timer",
                        value: vm.formattedElapsed,
                        label: "Durée"
                    )
                    miniStat(
                        icon: "location.fill",
                        value: "\(vm.locationManager.collectedPoints.count)",
                        label: "Points GPS"
                    )
                }

                // Motif input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Motif (optionnel)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    TextField("Ex : Visite client, réunion…", text: $vm.motif)
                        .padding(14)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(14)
                        .foregroundColor(.white)
                        .tint(.appPurple)
                        .submitLabel(.done)
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button("Abandonner") { onDiscard() }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(15)
                        .foregroundColor(.white.opacity(0.65))
                        .font(.subheadline)

                    Button("Enregistrer") { onSave() }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.appGreen)
                        .cornerRadius(15)
                        .foregroundColor(Color.appBackground)
                        .font(.subheadline.bold())
                }
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.12), lineWidth: 1))
            .padding(20)
        }
    }

    private func miniStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.appCyan)
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
    }
}
