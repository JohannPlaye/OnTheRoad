import SwiftUI

struct HistoryView: View {
    @StateObject private var vm = HistoryViewModel()
    @State private var selectedTrip: Trip?
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var isExporting = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                // Period picker
                periodPicker
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                // Custom date range
                customRangePicker
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                if vm.trips.isEmpty {
                    emptyState
                } else {
                    tripList
                }

                exportButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedTrip) { trip in
            TripDetailView(trip: trip)
                .onDisappear { vm.load() }
        }
        .onAppear { vm.load() }
        .onChange(of: vm.period)          { _, _ in vm.load() }
        .onChange(of: vm.isCustomPeriod)  { _, _ in vm.load() }
        .onChange(of: vm.customStartDate) { _, _ in if vm.isCustomPeriod { vm.load() } }
        .onChange(of: vm.customEndDate)   { _, _ in if vm.isCustomPeriod { vm.load() } }
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
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Historique")
                .font(.title3.bold())
                .foregroundColor(.white)

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

    // MARK: - Custom range picker

    private var customRangePicker: some View {
        HStack(spacing: 8) {
            // Toggle button
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

            DatePicker("", selection: $vm.customStartDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .colorScheme(.dark)
                .disabled(!vm.isCustomPeriod)
                .opacity(vm.isCustomPeriod ? 1 : 0.3)

            Spacer()

            Text("→")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))

            Spacer()

            DatePicker("", selection: $vm.customEndDate, in: vm.customStartDate..., displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .colorScheme(.dark)
                .disabled(!vm.isCustomPeriod)
                .opacity(vm.isCustomPeriod ? 1 : 0.3)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Trip list

    private var tripList: some View {
        ScrollView {
            LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                ForEach(vm.groupedTrips, id: \.day) { group in
                    Section {
                        VStack(spacing: 8) {
                            ForEach(group.trips, id: \.objectID) { trip in
                                Button { selectedTrip = trip } label: {
                                    TripRowView(trip: trip)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        vm.delete(trip)
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    } header: {
                        dayHeader(group.day)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private func dayHeader(_ date: Date) -> some View {
        HStack {
            Text(date.formatted(date: .complete, time: .omitted).capitalized)
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
            Spacer()

            let dayTrips = vm.groupedTrips.first(where: { $0.day == date })?.trips ?? []
            let dayKm = dayTrips.reduce(0) { $0 + $1.distance }
            Text(String(format: "%.1f km", dayKm))
                .font(.caption.bold())
                .foregroundColor(.appCyan)
        }
        .padding(.vertical, 6)
        .background(Color.appBackground)
    }

    // MARK: - Export button

    private var exportButton: some View {
        Button {
            guard !vm.trips.isEmpty else { return }
            isExporting = true
            DispatchQueue.global(qos: .userInitiated).async {
                let url = vm.csvFileURL()
                DispatchQueue.main.async {
                    isExporting = false
                    if let url {
                        shareItems = [url]
                        showShareSheet = true
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                if isExporting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text(vm.trips.isEmpty ? "Aucun trajet" : "Exporter et partager")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                vm.trips.isEmpty
                    ? AnyShapeStyle(Color.white.opacity(0.1))
                    : AnyShapeStyle(Color.appCyan)
            )
            .cornerRadius(16)
            .foregroundColor(vm.trips.isEmpty ? .white.opacity(0.3) : Color(red: 10/255, green: 22/255, blue: 42/255))
            .font(.headline)
        }
        .buttonStyle(.plain)
        .disabled(vm.trips.isEmpty || isExporting)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 48))
                .foregroundColor(.appPurple)
            Text("Aucun trajet")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Tes trajets apparaîtront ici après le premier enregistrement.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}
