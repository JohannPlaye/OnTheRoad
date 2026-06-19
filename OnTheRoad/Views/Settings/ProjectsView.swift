import SwiftUI

struct ProjectsView: View {
    @ObservedObject private var store = ProjectStore.shared
    @Environment(\.dismiss) private var dismiss

    // Création
    @State private var showAddAlert   = false
    @State private var newProjectName = ""

    // Renommage
    @State private var renamingProject: String? = nil
    @State private var renameText = ""

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                if store.projects.isEmpty {
                    emptyState
                } else {
                    projectsList
                }
            }
        }
        .navigationBarHidden(true)
        // Alert — ajout d'un projet
        .alert("Nouveau projet", isPresented: $showAddAlert) {
            TextField("Nom du projet", text: $newProjectName)
            Button("Ajouter") {
                store.add(newProjectName)
                newProjectName = ""
            }
            Button("Annuler", role: .cancel) { newProjectName = "" }
        }
        // Alert — renommage
        .alert("Renommer le projet", isPresented: Binding(
            get: { renamingProject != nil },
            set: { if !$0 { renamingProject = nil } }
        )) {
            TextField("Nouveau nom", text: $renameText)
            Button("Renommer") {
                if let old = renamingProject {
                    store.rename(old, to: renameText)
                }
                renamingProject = nil
            }
            Button("Annuler", role: .cancel) { renamingProject = nil }
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
            Text("Mes projets").font(.title3.bold()).foregroundColor(.white)
            Spacer()

            // Bouton ajout
            Button {
                newProjectName = ""
                showAddAlert   = true
            } label: {
                Image(systemName: "plus")
                    .font(.headline).foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Liste

    private var projectsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(store.projects, id: \.self) { project in
                    projectRow(project)
                    if project != store.projects.last {
                        Divider().background(Color.white.opacity(0.07))
                    }
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private func projectRow(_ project: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "folder.fill")
                .foregroundColor(.appOrange)
                .frame(width: 22)

            Text(project)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            // Renommer
            Button {
                renameText      = project
                renamingProject = project
            } label: {
                Image(systemName: "pencil")
                    .font(.subheadline)
                    .foregroundColor(.appPurple)
                    .frame(width: 32, height: 32)
                    .background(Color.appPurple.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)

            // Supprimer
            Button {
                withAnimation { store.delete(project) }
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundColor(.appPink)
                    .frame(width: 32, height: 32)
                    .background(Color.appPink.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.2))
            Text("Aucun projet")
                .font(.headline)
                .foregroundColor(.white.opacity(0.35))
            Text("Appuie sur + pour créer ton premier projet.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.25))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}
