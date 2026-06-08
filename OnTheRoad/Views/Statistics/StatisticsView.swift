import SwiftUI

struct StatisticsView: View {
    @StateObject private var vm = StatisticsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                periodPicker
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                customRangePicker
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 16) {
                        globalGrid
                        if !vm.dailyStats.isEmpty {
                            dailySection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .background(NavBarHider())
        .onAppear { vm.load() }
        .onChange(of: vm.period)          { _, _ in vm.load() }
        .onChange(of: vm.isCustomPeriod)  { _, _ in vm.load() }
        .onChange(of: vm.customStartDate) { _, _ in if vm.isCustomPeriod { vm.load() } }
        .onChange(of: vm.customEndDate)   { _, _ in if vm.isCustomPeriod { vm.load() } }
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
            Text("Statistiques")
                .font(.title3.bold()).foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
    }

    // MARK: - Period picker

    private var periodPicker: some View {
        HStack(spacing: 6) {
            ForEach(HistoryPeriod.allCases) { p in
                Button(p.rawValue) {
                    vm.isCustomPeriod = false
                    vm.period = p
                }
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    vm.period == p && !vm.isCustomPeriod
                        ? AnyShapeStyle(Color.appGreen)
                        : AnyShapeStyle(Color.white.opacity(0.07))
                )
                .foregroundColor(vm.period == p && !vm.isCustomPeriod ? .white : .white.opacity(0.55))
                .cornerRadius(10)
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var customRangePicker: some View {
        HStack(spacing: 8) {
            Button {
                vm.isCustomPeriod.toggle()
            } label: {
                Image(systemName: vm.isCustomPeriod ? "calendar.badge.checkmark" : "calendar")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(vm.isCustomPeriod ? AnyShapeStyle(Color.appCyan) : AnyShapeStyle(Color.white.opacity(0.07)))
                .foregroundColor(vm.isCustomPeriod ? Color.appBackground : .white.opacity(0.55))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            Spacer()

            DatePicker("", selection: $vm.customStartDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .colorScheme(.dark)
                .disabled(!vm.isCustomPeriod)
                .opacity(vm.isCustomPeriod ? 1 : 0.3)

            Text("→")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))

            DatePicker("", selection: $vm.customEndDate, in: vm.customStartDate..., displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .colorScheme(.dark)
                .disabled(!vm.isCustomPeriod)
                .opacity(vm.isCustomPeriod ? 1 : 0.3)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Global grid

    private var globalGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                bigStat(icon: "road.lanes",
                        value: String(format: "%.0f km", vm.totalDistance),
                        label: "Distance totale",
                        color: .appGreen)
                bigStat(icon: "car.fill",
                        value: "\(vm.totalTripCount)",
                        label: vm.totalTripCount == 1 ? "trajet" : "trajets",
                        color: .appCyan)
            }
            HStack(spacing: 10) {
                bigStat(icon: "timer",
                        value: vm.formattedTotalDuration,
                        label: "Durée cumulée",
                        color: .appGreen)
                bigStat(icon: "chart.line.uptrend.xyaxis",
                        value: String(format: "%.1f km/j", vm.avgDistancePerDay),
                        label: "Moyenne / jour",
                        color: .appCyan)
            }
        }
    }

    private func bigStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Daily breakdown

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Jour par jour")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(vm.dailyStats) { stat in
                dayRow(stat)
            }
        }
    }

    private func dayRow(_ stat: DayStat) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(stat.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text("\(stat.tripCount) trajet\(stat.tripCount > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.45))
            }
            Spacer()
            Text(String(format: "%.1f km", stat.distance))
                .font(.subheadline.bold())
                .foregroundColor(.appCyan)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
