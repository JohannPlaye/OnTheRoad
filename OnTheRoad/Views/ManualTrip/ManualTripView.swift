import SwiftUI
import MapKit

struct ManualTripView: View {
    @StateObject private var vm = ManualTripViewModel()
    @Environment(\.dismiss) private var dismiss

    // FocusState — fiable sur TextField, contrairement à onTapGesture
    @FocusState private var focusedField: AddressField?
    enum AddressField: Hashable { case departure, arrival }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 16) {
                        addressCard
                        if vm.selectedDeparture != nil || vm.selectedArrival != nil { mapCard }
                        if vm.isLoadingRoute    { loadingCard }
                        if let err = vm.routeError { errorCard(err) }
                        if !vm.routes.isEmpty {
                            if vm.routes.count > 1 { routePickerCard }
                            routeInfoCard
                        }
                        if vm.selectedRoute != nil { detailsCard }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, vm.canSave ? 100 : 32)
                }
            }

            if vm.canSave {
                saveButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: vm.isSaved) { _, saved in if saved { dismiss() } }
        // Ferme le clavier si on tape en dehors des champs
        .onTapGesture { focusedField = nil }
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
            Text("Trajet manuel").font(.title3.bold()).foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
    }

    // MARK: - Address card

    private var addressCard: some View {
        VStack(spacing: 0) {
            departureFieldSection
            Divider().background(Color.white.opacity(0.08))
            arrivalFieldSection
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    // MARK: Departure field + results

    private var departureFieldSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "flag.fill")
                    .foregroundColor(.appGreen).frame(width: 20)
                TextField("Adresse de départ", text: $vm.departureQuery)
                    .foregroundColor(.white).tint(.appCyan).font(.subheadline)
                    .focused($focusedField, equals: .departure)
                    .onChange(of: vm.departureQuery) { _, val in
                        vm.onDepartureQueryChange(val)
                    }
                if !vm.departureQuery.isEmpty {
                    Button { vm.clearDeparture(); focusedField = .departure } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.35))
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)

            if focusedField == .departure && !vm.departureResults.isEmpty {
                Divider().background(Color.white.opacity(0.06))
                resultsList(items: vm.departureResults) { item in
                    focusedField = nil
                    vm.selectDeparture(item)
                }
            }
        }
    }

    // MARK: Arrival field + results

    private var arrivalFieldSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "flag.checkered")
                    .foregroundColor(.appPink).frame(width: 20)
                TextField("Adresse d'arrivée", text: $vm.arrivalQuery)
                    .foregroundColor(.white).tint(.appCyan).font(.subheadline)
                    .focused($focusedField, equals: .arrival)
                    .onChange(of: vm.arrivalQuery) { _, val in
                        vm.onArrivalQueryChange(val)
                    }
                if !vm.arrivalQuery.isEmpty {
                    Button { vm.clearArrival(); focusedField = .arrival } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.35))
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)

            if focusedField == .arrival && !vm.arrivalResults.isEmpty {
                Divider().background(Color.white.opacity(0.06))
                resultsList(items: vm.arrivalResults) { item in
                    focusedField = nil
                    vm.selectArrival(item)
                }
            }
        }
    }

    // MARK: Results list

    private func resultsList(items: [MKMapItem], onSelect: @escaping (MKMapItem) -> Void) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                Button { onSelect(item) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin")
                            .font(.caption).foregroundColor(.appCyan).frame(width: 16)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "")
                                .font(.subheadline).foregroundColor(.white)
                                .lineLimit(1)
                            if let sub = item.placemark.title, sub != item.name {
                                Text(sub)
                                    .font(.caption2).foregroundColor(.white.opacity(0.45))
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if idx < items.count - 1 {
                    Divider().background(Color.white.opacity(0.05)).padding(.leading, 42)
                }
            }
        }
    }

    // MARK: - Map

    private var mapCard: some View {
        ManualTripMapView(
            route:     vm.selectedRoute,
            departure: vm.selectedDeparture,
            arrival:   vm.selectedArrival
        )
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Loading / error

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView().tint(.appCyan)
            Text("Calcul de l'itinéraire…").font(.subheadline).foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.appOrange)
                Text(message).font(.subheadline).foregroundColor(.white.opacity(0.7))
            }
            Button { vm.tryCalculateRoute() } label: {
                Text("Réessayer")
                    .font(.subheadline.bold())
                    .foregroundColor(Color.appBackground)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.appOrange, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appOrange.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Route picker

    private var routePickerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Itinéraires disponibles")
                .font(.caption).foregroundColor(.white.opacity(0.5))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.routes.indices, id: \.self) { i in
                        let route    = vm.routes[i]
                        let selected = i == vm.selectedRouteIndex
                        Button { vm.selectedRouteIndex = i } label: {
                            VStack(spacing: 4) {
                                Text(route.name.isEmpty ? "Option \(i + 1)" : route.name)
                                    .font(.caption.bold())
                                    .foregroundColor(selected ? Color.appBackground : .white)
                                Text(formatDuration(route.expectedTravelTime))
                                    .font(.caption2)
                                    .foregroundColor(selected ? Color.appBackground.opacity(0.7) : .white.opacity(0.55))
                                Text(String(format: "%.1f km", route.distance / 1000))
                                    .font(.caption2)
                                    .foregroundColor(selected ? Color.appBackground.opacity(0.7) : .white.opacity(0.55))
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(selected ? Color.appCyan : Color.white.opacity(0.07),
                                        in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Route info

    private var routeInfoCard: some View {
        HStack(spacing: 0) {
            routeStat(icon: "road.lanes",  color: .appCyan,   value: vm.formattedDistance, label: "Distance")
            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 40)
            routeStat(icon: "timer",       color: .appPurple, value: vm.formattedDuration, label: "Durée estimée")
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func routeStat(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundColor(color)
            Text(value).font(.subheadline.bold()).foregroundColor(.white)
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Details card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            // Date
            detailRow {
                HStack(spacing: 10) {
                    Image(systemName: "calendar").foregroundColor(.appCyan).frame(width: 20)
                    Text("Date").font(.subheadline).foregroundColor(.white.opacity(0.7))
                    Spacer()
                    DatePicker("", selection: $vm.tripDate, in: ...Date(), displayedComponents: .date)
                        .labelsHidden().colorScheme(.dark).tint(.appCyan)
                }
            }
            Divider().background(Color.white.opacity(0.07))

            // Time mode
            detailRow {
                HStack(spacing: 10) {
                    Image(systemName: "clock").foregroundColor(.appCyan).frame(width: 20)
                    Picker("", selection: $vm.timeMode) {
                        ForEach(ManualTripViewModel.TimeMode.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented).colorScheme(.dark)
                }
            }
            Divider().background(Color.white.opacity(0.07))

            // Anchor time
            detailRow {
                HStack(spacing: 10) {
                    Image(systemName: vm.timeMode == .departure ? "play.circle" : "stop.circle")
                        .foregroundColor(vm.timeMode == .departure ? .appGreen : .appPink)
                        .frame(width: 20)
                    Text(vm.timeMode == .departure ? "Heure de départ" : "Heure d'arrivée")
                        .font(.subheadline).foregroundColor(.white.opacity(0.7))
                    Spacer()
                    DatePicker("", selection: $vm.anchorTime, displayedComponents: .hourAndMinute)
                        .labelsHidden().colorScheme(.dark).tint(.appCyan)
                }
            }
            Divider().background(Color.white.opacity(0.07))

            // Computed other time (read-only)
            detailRow {
                HStack(spacing: 10) {
                    Image(systemName: vm.timeMode == .departure ? "stop.circle" : "play.circle")
                        .foregroundColor(vm.timeMode == .departure ? .appPink : .appGreen)
                        .frame(width: 20)
                    Text(vm.timeMode == .departure ? "Arrivée estimée" : "Départ estimé")
                        .font(.subheadline).foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(vm.timeMode == .departure ? vm.formattedArrival : vm.formattedDeparture)
                        .font(.subheadline.bold()).foregroundColor(.appCyan)
                }
            }
            Divider().background(Color.white.opacity(0.07))

            // Motif
            detailRow {
                HStack(spacing: 10) {
                    Image(systemName: "text.bubble").foregroundColor(.appCyan).frame(width: 20)
                    TextField("Motif (optionnel)", text: $vm.motif)
                        .font(.subheadline).foregroundColor(.white).tint(.appCyan)
                }
            }
            Divider().background(Color.white.opacity(0.07))

            // Project
            detailRow {
                HStack(spacing: 10) {
                    Image(systemName: "folder").foregroundColor(.appOrange).frame(width: 20)
                    Text("Projet (obligatoire)")
                        .font(.subheadline).foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Menu {
                        ForEach(TripProject.allCases) { p in
                            Button(p.rawValue) { vm.selectedProject = p }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(vm.selectedProject?.rawValue ?? "Sélectionner…")
                                .font(.subheadline)
                                .foregroundColor(vm.selectedProject == nil ? .white.opacity(0.35) : .white)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2).foregroundColor(.white.opacity(0.35))
                        }
                    }
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func detailRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content().padding(.horizontal, 16).padding(.vertical, 14)
    }

    // MARK: - Save button

    private var saveButton: some View {
        Button { vm.save() } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                Text("Enregistrer le trajet").font(.headline)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 17)
            .background(Color.appCyan).cornerRadius(18)
            .foregroundColor(Color.appBackground)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let s = Int(seconds); let h = s / 3600; let m = (s % 3600) / 60
        return h > 0 ? "\(h)h\(String(format: "%02d", m))" : "\(m) min"
    }
}
