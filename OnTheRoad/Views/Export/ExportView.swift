import SwiftUI

struct ExportView: View {
    @StateObject private var vm = ExportViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var isGenerating = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                ScrollView {
                    exportCard
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .background(NavBarHider())
        .onAppear { vm.load() }
        .sheet(isPresented: $showShareSheet) {
            if !shareItems.isEmpty {
                ShareSheet(items: shareItems)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline).foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Exporter")
                .font(.title3.bold()).foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
    }

    // MARK: - Export card

    private var exportCard: some View {
        VStack(spacing: 28) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 56))
                .foregroundColor(.appOrange)

            VStack(spacing: 8) {
                Text("Export CSV")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("\(vm.tripCount) trajet\(vm.tripCount == 1 ? "" : "s") à exporter")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }

            // Format info
            infoRow(icon: "textformat",         text: "Encodage UTF-8 avec BOM")
            infoRow(icon: "list.bullet",         text: "Séparateur point-virgule (;)")
            infoRow(icon: "number",             text: "Décimales avec virgule (format FR)")
            infoRow(icon: "location.fill",      text: "Coordonnées GPS départ et arrivée")

            Button {
                guard vm.tripCount > 0 else { return }
                isGenerating = true
                DispatchQueue.global(qos: .userInitiated).async {
                    let url = vm.csvFileURL()
                    DispatchQueue.main.async {
                        isGenerating = false
                        if let url {
                            shareItems = [url]
                            showShareSheet = true
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    if isGenerating {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text(vm.tripCount == 0 ? "Aucun trajet" : "Exporter et partager")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    vm.tripCount == 0
                        ? AnyShapeStyle(Color.white.opacity(0.1))
                        : AnyShapeStyle(Color.appCyan)
                )
                .cornerRadius(16)
                .foregroundColor(vm.tripCount == 0 ? .white.opacity(0.3) : Color(red: 10/255, green: 22/255, blue: 42/255))
                .font(.headline)
            }
            .buttonStyle(.plain)
            .disabled(vm.tripCount == 0 || isGenerating)
        }
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.appCyan)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.65))
            Spacer()
        }
    }
}
