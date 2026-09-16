import SwiftUI

struct CaughtListView: View {

    let kind: CaughtListKind

    @EnvironmentObject private var lists: ListsController

    private var pokemonIds: [Int] {
        kind == .shiny ? lists.shinyCaught : lists.regularCaught
    }

    var body: some View {
        ScrollView {
            PokemonGrid(
                pokemonIds: pokemonIds,
                emptyState: EmptyStateView(
                    systemImage: kind.systemImage,
                    title: kind == .shiny ? "No shinies yet" : "Nothing caught yet",
                    message: "Mark a Pokémon as \(kind == .shiny ? "Shiny Caught" : "Caught") "
                        + "on its detail screen and it shows up here."
                ),
                showsShinySprites: kind == .shiny,
                showsBadges: false
            )
            .padding(16)
        }
        .navigationTitle(kind.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CaughtListView(kind: .shiny)
            .withPokeHunterDestinations()
    }
    .environmentObject(ListsController())
}
