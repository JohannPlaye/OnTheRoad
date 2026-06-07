import SwiftUI

struct TripDetailView: View {
    @StateObject private var vm: TripDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false

    init(trip: Trip) {
        _vm = StateObject(wrappedValue: TripDetailViewModel(trip: trip))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Map
                    TripDetailMapView(coordinates: vm.trip.gpsCoordinates)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 20)

                    // Stats
                    statsGrid
                        .padding(.horizontal, 20)

                    // Motif
                    if let motif = vm.trip.motif, !motif.isEmpty {
                        motifCard(motif)
                            .padding(.horizontal, 20)
                    }

                    // Timestamps
                    timestampCard
                        .padding(.horizontal, 20)

                    // Actions
                    actionRow
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .confirmationDialog("Supprimer ce trajet ?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) {
                vm.delete()
                dismiss()
            }
            Button("Annuler", role: .cancel) {}
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = vm.csvFileURL() {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(vm.trip.formattedDate)
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(vm.trip.formattedStartTime) → \(vm.trip.formattedEndTime)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        HStack(spacing: 10) {
            statCard(icon: "road.lanes",  value: vm.trip.formattedDistance,     label: "Distance")
            statCard(icon: "timer",       value: vm.trip.formattedDuration,     label: "Durée")
            statCard(icon: "speedometer", value: vm.trip.formattedAverageSpeed, label: "Moy.")
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
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
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Motif

    private func motifCard(_ motif: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "text.bubble.fill")
                .foregroundColor(.appCyan)
            Text(motif)
                .foregroundColor(.white)
                .font(.subheadline)
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Timestamps

    private var timestampCard: some View {
        HStack(spacing: 0) {
            timestampItem(icon: "flag.fill",       color: .appGreen,  label: "Départ",  value: vm.trip.formattedStartTime)
            Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 36)
            timestampItem(icon: "flag.checkered",  color: .appPurple, label: "Arrivée", value: vm.trip.formattedEndTime)
        }
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func timestampItem(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption2).foregroundColor(.white.opacity(0.4))
                Text(value).font(.subheadline.bold()).foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                showShareSheet = true
            } label: {
                Label("Exporter CSV", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)

            Button {
                showDeleteConfirm = true
            } label: {
                Label("Supprimer", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.red.opacity(0.25), lineWidth: 1))
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
