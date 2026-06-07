import SwiftUI
import CoreData

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var navigateToTrip = false
    @State private var navigateToHistory = false
    @State private var navigateToStats = false
    @State private var navigateToExport = false

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

                    Spacer()

                    bottomNav
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
                .foregroundColor(.appPurple)
        }
    }

    // MARK: - Today stats card

    private var todayCard: some View {
        HStack(spacing: 0) {
            statItem(
                value: "\(vm.todayTripCount)",
                label: vm.todayTripCount == 1 ? "trajet" : "trajets"
            )
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 40)
            statItem(
                value: String(format: "%.1f km", vm.todayDistance),
                label: "aujourd'hui"
            )
        }
        .padding(.vertical, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.appCyan)
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
                    .fill(Color.appPurple)
                    .frame(width: 168, height: 168)
                    .shadow(color: .appPurple.opacity(0.55), radius: 36, x: 0, y: 12)

                VStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    Text("Démarrer")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom nav

    private var bottomNav: some View {
        HStack(spacing: 0) {
            navItem(icon: "clock.fill",                 label: "Historique")  { navigateToHistory = true }
            navItem(icon: "chart.bar.fill",             label: "Stats")       { navigateToStats = true }
            navItem(icon: "square.and.arrow.up.fill",   label: "Exporter")    { navigateToExport = true }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func navItem(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.appCyan)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.55))
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
