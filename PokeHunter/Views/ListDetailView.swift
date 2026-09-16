import SwiftUI

struct ListDetailView: View {

    let listId: UUID

    @EnvironmentObject private var lists: ListsController

    @State private var isRenaming = false
    @State private var draftName = ""

    private var list: PokemonList? {
        lists.customLists.first { $0.id == listId }
    }

    var body: some View {
        Group {
            if let list {
                content(for: list)
            } else {
                EmptyStateView(systemImage: "trash", title: "This list no longer exists")
            }
        }
        .navigationTitle(list?.name ?? "List")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { lists.refresh() }
    }

    private func content(for list: PokemonList) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                AddPokemonBar { detail in
                    lists.add(detail.id, to: list)
                }

                PokemonGrid(
                    pokemonIds: lists.pokemonIds(in: list),
                    emptyState: EmptyStateView(
                        systemImage: "tray",
                        title: "This list is empty",
                        message: "Add a Pokémon by name or Pokédex number above."
                    ),
                    onRemove: { pokemonId in
                        lists.remove(pokemonId, from: list)
                    }
                )
            }
            .padding(16)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Rename", systemImage: "pencil") {
                        draftName = list.name
                        isRenaming = true
                    }
                    Button("Delete List", systemImage: "trash", role: .destructive) {
                        lists.delete(list)
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .alert("Rename List", isPresented: $isRenaming) {
            TextField("List name", text: $draftName)
            Button("Cancel", role: .cancel) {}
            Button("Save") { lists.rename(list, to: draftName) }
        }
    }
}

#Preview {
    NavigationStack {
        ListDetailView(listId: UUID())
            .withPokeHunterDestinations()
    }
    .environmentObject(ListsController())
}
