import Foundation

struct PokemonSummary: Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    var types: [String] = []

    var displayName: String { name.pokemonDisplayName }

    var generation: Int { Constants.Generations.generation(for: id) ?? 0 }

    var isLegendary: Bool { Constants.Rarity.isLegendary(id) }

    var isMythical: Bool { Constants.Rarity.isMythical(id) }

    var spriteURL: URL { Constants.API.spriteURL(for: id) }

    var shinySpriteURL: URL { Constants.API.spriteURL(for: id, shiny: true) }
}
