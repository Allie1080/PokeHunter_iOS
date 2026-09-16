import SwiftUI

struct CreateListModal: View {

    // the Add-to-Lists sheet uses this to tick the list it just create
    var onCreated: ((PokemonList) -> Void)?

    @EnvironmentObject private var lists: ListsController
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var pendingIds: [Int] = []
    @State private var pendingSummaries: [PokemonSummary] = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("List Information")
                            .font(.headline)

                        TextField("List Name", text: $name)
                            .textInputAutocapitalization(.words)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                Color(.secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Pokémon")
                            .font(.headline)

                        AddPokemonBar { detail in
                            guard !pendingIds.contains(detail.id) else { return }
                            pendingIds.append(detail.id)
                            pendingSummaries.append(detail.summary)
                        }
                    }

                    if pendingSummaries.isEmpty {
                        Text("Nothing added yet. You can also add Pokémon after creating the list.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(pendingSummaries) { summary in
                                PokemonCard(pokemon: summary, onRemove: { remove(summary.id) })
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(!canCreate)
                }
            }
        }
    }

    private func remove(_ pokemonId: Int) {
        pendingIds.removeAll { $0 == pokemonId }
        pendingSummaries.removeAll { $0.id == pokemonId }
    }

    private func create() {
        guard let list = lists.createList(named: name) else { return }
        for id in pendingIds {
            lists.add(id, to: list)
        }
        onCreated?(list)
        dismiss()
    }
}

#Preview {
    CreateListModal()
        .environmentObject(ListsController())
}
