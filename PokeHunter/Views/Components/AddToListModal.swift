import SwiftUI

struct AddToListModal: View {

    let pokemonId: Int

    @EnvironmentObject private var lists: ListsController
    @Environment(\.dismiss) private var dismiss

    @State private var selection: Set<UUID> = []
    @State private var isCreatingList = false

    var body: some View {
        NavigationStack {
            List {
                Section("Lists") {
                    if lists.customLists.isEmpty {
                        Text("No lists yet.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(lists.customLists) { list in
                        Button {
                            toggle(list)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(list.name)
                                        .foregroundStyle(Color.primary)
                                    Text("\(lists.count(for: list)) Pokémon")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }

                                Spacer()

                                if selection.contains(list.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Button {
                        isCreatingList = true
                    } label: {
                        Label("New List", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Add to Lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        lists.setMembership(pokemonId: pokemonId, listIds: selection)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isCreatingList) {
                // A list created from here starts out ticked — the user is mid-add.
                CreateListModal { created in
                    selection.insert(created.id)
                }
                .environmentObject(lists)
            }
        }
        .onAppear {
            selection = lists.listIds(containing: pokemonId)
        }
    }

    private func toggle(_ list: PokemonList) {
        if selection.contains(list.id) {
            selection.remove(list.id)
        } else {
            selection.insert(list.id)
        }
    }
}

#Preview {
    AddToListModal(pokemonId: 1)
        .environmentObject(ListsController())
}
