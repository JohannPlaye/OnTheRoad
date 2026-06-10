import SwiftUI
import CoreData

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var navigateToTrip = false
    @State private var navigateToHistory = false
    @State private var navigateToStats = false
    @State private var navigateToExport = false
    @State private var navigateToDeclare = false
    @State private var navigateToManualTrip = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                        .padding(.top, 8)

                    Spacer()

                    todayCard

                    Spacer()

                    startButton

                    manualTripButton

                    Spacer()

                    bottomNavArea
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToTrip) {
                TripView()
                    .onDisappear { vm.refresh() }
            }
            .navigationDestination(isPresented: $navigateToHistory) {
                HistoryView()
            }
            .navigationDestination(isPresented: $navigateToStats) {
                StatisticsView()
            }
            .navigationDestination(isPresented: $navigateToExport) {
                ExportView()
            }
            .navigationDestination(isPresented: $navigateToDeclare) {
                MileageDeclarationView()
            }
            .navigationDestination(isPresented: $navigateToManualTrip) {
                ManualTripView()
                    .onDisappear { vm.refresh() }
            }
        }
        .onAppear { vm.refresh() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("OnTheRoad")
                    .font(.title.bold())
                    .foregroundColor(.appCyan)
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.45))
            }
            Spacer()
            Image(systemName: "car.fill")
                .font(.title2)
                .foregroundColor(.appGreen)
        }
    }

    // MARK: - Today stats card

    private var todayCard: some View {
        VStack(spacing: 0) {
            Text("Aujourd'hui")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            HStack(spacing: 0) {
                statItem(
                    value: "\(vm.todayTripCount)",
                    label: vm.todayTripCount == 1 ? "trajet" : "trajets"
                )
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 40)
                statItem(
                    value: String(format: "%.1f", vm.todayDistance),
                    label: "km"
                )
            }
            .padding(.bottom, 20)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.appGreen)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Start button

    private var startButton: some View {
        Button { navigateToTrip = true } label: {
            ZStack {
                Circle()
                    .fill(Color.appCyan)
                    .frame(width: 168, height: 168)
                    .shadow(color: .appCyan.opacity(0.45), radius: 36, x: 0, y: 12)

                VStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(Color.appBackground)
                    Text("Démarrer")
                        .font(.headline)
                        .foregroundColor(Color.appBackground)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Manual trip button

    private var manualTripButton: some View {
        Button { navigateToManualTrip = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "map")
                    .font(.subheadline)
                Text("Saisir un trajet manuellement")
                    .font(.subheadline)
            }
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.top, 16)
    }

    // MARK: - Bottom nav

    private var bottomNavArea: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 8
            let mainWidth  = (proxy.size.width - spacing) * 2/3
            let declWidth  = (proxy.size.width - spacing) * 1/3

            HStack(spacing: spacing) {
                // 2/3 — Historique + Stats
                HStack(spacing: 0) {
                    navItem(icon: "clock.fill",      label: "Historique") { navigateToHistory = true }
                    navItem(icon: "chart.bar.fill",  label: "Stats")      { navigateToStats   = true }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
                .frame(width: mainWidth, height: proxy.size.height)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.1), lineWidth: 1))

                // 1/3 — Déclaration km
                HStack(spacing: 0) {
                    navItem(icon: "list.bullet.clipboard", label: "Déclaration km") { navigateToDeclare = true }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
                .frame(width: declWidth, height: proxy.size.height)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
        .frame(height: 70)
    }

    private func navItem(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.appGreen)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
