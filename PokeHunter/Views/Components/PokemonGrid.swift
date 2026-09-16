import SwiftUI

struct PokemonGrid: View {

    let pokemonIds: [Int]
    var emptyState: EmptyStateView?

    // used by the Shiny caught list
    var showsShinySprites = false
    // false for the Caught lists, cause all of them are known to be caught
    var showsBadges = true
    // nil on Caught lists
    var onRemove: ((Int) -> Void)?

    @State private var summaries: [PokemonSummary] = []
    @State private var isResolving = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        Group {
            if pokemonIds.isEmpty {
                emptyState ?? EmptyStateView(systemImage: "tray", title: "Nothing here yet")

            } else if summaries.isEmpty && isResolving {
                ProgressView()
                    .padding(.vertical, 40)

            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(summaries) { summary in
                        NavigationLink(value: Route.detail(pokemonId: summary.id)) {
                            PokemonCard(
                                pokemon: summary,
                                showsBadges: showsBadges,
                                showsShinySprite: showsShinySprites,
                                onRemove: onRemove == nil
                                    ? nil
                                    : { onRemove?(summary.id) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .task(id: pokemonIds) { await resolve() }
    }

    // lists show Pokemon in the order they were added.
    private func resolve() async {
        guard !pokemonIds.isEmpty else {
            summaries = []
            return
        }

        isResolving = true
        defer { isResolving = false }

        guard let index = try? await PokemonAPIWrapper.shared.fetchIndex() else {
            summaries = pokemonIds.map { PokemonSummary(id: $0, name: "") }
            return
        }

        let byId = Dictionary(uniqueKeysWithValues: index.map { ($0.id, $0) })
        summaries = pokemonIds.map { id in
            byId[id] ?? PokemonSummary(id: id, name: "")
        }
    }
}
