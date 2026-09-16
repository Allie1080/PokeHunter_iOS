import SwiftUI

struct PokemonCard: View {

    let pokemon: PokemonSummary
    var showsBadges = true
    var showsShinySprite = false
    var onRemove: (() -> Void)?

    @EnvironmentObject private var lists: ListsController

    private var isCaught: Bool { showsBadges && lists.isCaught(pokemon.id) }
    private var isShinyCaught: Bool { showsBadges && lists.isShinyCaught(pokemon.id) }

    var body: some View {
        VStack(spacing: 2) {
            ZStack(alignment: .topTrailing) {
                SpriteImage(url: showsShinySprite ? pokemon.shinySpriteURL : pokemon.spriteURL, size: 72)
                    .frame(maxWidth: .infinity)

                if isShinyCaught {
                    badge(systemImage: "sparkles", tint: Color(hex: "F2B705"))
                } else if isCaught {
                    badge(systemImage: "checkmark.circle.fill", tint: Color(hex: "34C759"))
                }
            }

            Text(pokemon.id.pokedexNumber)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(pokemon.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .contextMenu {
            if let onRemove {
                Button("Remove from list", systemImage: "minus.circle", role: .destructive, action: onRemove)
            }
        }
    }

    private func badge(systemImage: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .font(.caption)
            .foregroundStyle(tint)
            .padding(3)
            .background(.thinMaterial, in: Circle())
            .padding(4)
    }

    private var accessibilityLabel: String {
        var parts = ["\(pokemon.displayName), \(pokemon.id.pokedexNumber)"]
        if isShinyCaught { parts.append("shiny caught") }
        else if isCaught { parts.append("caught") }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
        PokemonCard(pokemon: PokemonSummary(id: 1, name: "bulbasaur"))
        PokemonCard(pokemon: PokemonSummary(id: 4, name: "charmander"))
        PokemonCard(pokemon: PokemonSummary(id: 29, name: "nidoran-f"))
    }
    .padding()
    .environmentObject(ListsController())
}
