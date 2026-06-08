import SwiftUI

struct MileageDeclarationView: View {
    @StateObject private var vm = MileageDeclarationViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                if vm.declarations.isEmpty {
                    emptyState
                } else {
                    declarationList
                }

                addButton
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
            }
        }
        .navigationBarHidden(true)
        .background(NavBarHider())
        .onAppear { vm.load() }
        // Add sheet
        .sheet(isPresented: $vm.showAddSheet) {
            addSheet
        }
        // Edit confirmation
        .alert(editAlertTitle, isPresented: $vm.showEditConfirm, presenting: vm.editingEntry) { entry in
            TextField("Kilométrage", text: $vm.editKilometers)
                .keyboardType(.decimalPad)
            Button("Confirmer") { vm.confirmEdit() }
            Button("Annuler", role: .cancel) {
                vm.showEditConfirm = false
                vm.editingEntry    = nil
                vm.editError       = nil
            }
        } message: { entry in
            if let err = vm.editError {
                Text(err)
            } else {
                Text("Modifier le kilométrage déclaré pour \(entry.formattedMonthYear)")
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
            Text("Déclaration km")
                .font(.title3.bold()).foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
    }

    // MARK: - List

    private var declarationList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(vm.declarations, id: \.objectID) { entry in
                    declarationRow(entry)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private func declarationRow(_ entry: MileageDeclaration) -> some View {
        HStack(spacing: 14) {
            // Month/year
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.formattedMonthYear)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }

            Spacer()

            // Km value
            Text(String(format: "%.0f km", entry.kilometers))
                .font(.subheadline.bold())
                .foregroundColor(.appCyan)

            // Edit button
            Button {
                vm.startEdit(entry)
            } label: {
                Image(systemName: "pencil")
                    .font(.caption.bold())
                    .foregroundColor(.appPurple)
                    .frame(width: 32, height: 32)
                    .background(Color.appPurple.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { vm.delete(entry) } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }

    // MARK: - Add button

    private var addButton: some View {
        Button {
            vm.prepareAdd()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                Text(vm.availableMonthYears.isEmpty ? "Tous les mois sont déclarés" : "Nouvelle déclaration")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                vm.availableMonthYears.isEmpty
                    ? AnyShapeStyle(Color.white.opacity(0.1))
                    : AnyShapeStyle(Color.appCyan)
            )
            .cornerRadius(16)
            .foregroundColor(vm.availableMonthYears.isEmpty ? .white.opacity(0.3) : Color.appBackground)
            .font(.headline)
        }
        .buttonStyle(.plain)
        .disabled(vm.availableMonthYears.isEmpty)
    }

    // MARK: - Add sheet

    private var addSheet: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Month/year picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mois concerné")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        if vm.availableMonthYears.isEmpty {
                            Text("Tous les mois récents sont déjà déclarés.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            Picker("Mois", selection: Binding(
                                get: { vm.selectedMonthYearIndex },
                                set: { idx in
                                    let entry = vm.availableMonthYears[idx]
                                    vm.newMonth = entry.month
                                    vm.newYear  = entry.year
                                }
                            )) {
                                ForEach(Array(vm.availableMonthYears.enumerated()), id: \.offset) { idx, my in
                                    Text(vm.labelFor(month: my.month, year: my.year)).tag(idx)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 150)
                            .colorScheme(.dark)
                        }
                    }

                    // Km input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kilométrage au début du mois (km)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        TextField("Ex : 45200", text: $vm.newKilometers)
                            .keyboardType(.decimalPad)
                            .padding(14)
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(14)
                            .foregroundColor(.white)
                            .tint(.appCyan)
                    }

                    if let err = vm.errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.appPink)
                    }

                    Spacer()

                    Button("Enregistrer") { vm.confirmAdd() }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color.appGreen)
                        .cornerRadius(16)
                        .foregroundColor(Color.appBackground)
                        .font(.headline.bold())
                        .buttonStyle(.plain)
                        .disabled(vm.availableMonthYears.isEmpty)
                }
                .padding(24)
            }
            .navigationTitle("Nouvelle déclaration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { vm.showAddSheet = false }
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .colorScheme(.dark)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.appPurple)
            Text("Aucune déclaration")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Enregistre le kilométrage de ton véhicule au début de chaque mois.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Helpers

    private var editAlertTitle: String {
        guard let entry = vm.editingEntry else { return "Modifier" }
        return "Modifier — \(entry.formattedMonthYear)"
    }
}
