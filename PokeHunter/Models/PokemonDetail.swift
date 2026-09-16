import Foundation


struct SpriteSet: Equatable {
    var frontDefault: URL?
    var frontShiny: URL?
    var frontFemale: URL?
    var frontShinyFemale: URL?
    var backDefault: URL?
    var backShiny: URL?
    var backFemale: URL?
    var backShinyFemale: URL?

    var hasFemaleSprite: Bool { frontFemale != nil }

    func url(front: Bool, shiny: Bool, female: Bool) -> URL? {
        switch (front, shiny, female) {
        case (true,  false, false): return frontDefault
        case (true,  true,  false): return frontShiny
        case (true,  false, true):  return frontFemale ?? frontDefault
        case (true,  true,  true):  return frontShinyFemale ?? frontShiny
        case (false, false, false): return backDefault
        case (false, true,  false): return backShiny
        case (false, false, true):  return backFemale ?? backDefault
        case (false, true,  true):  return backShinyFemale ?? backShiny
        }
    }
}


struct StatValue: Identifiable, Equatable {
    let key: String          // "special-attack"
    let value: Int

    var id: String { key }

    var displayName: String {
        Constants.Stats.displayNames[key] ?? key.capitalizedWords
    }
}


struct AbilityEntry: Identifiable, Equatable {
    let name: String
    let isHidden: Bool

    var id: String { name }

    var displayName: String { name.capitalizedWords }
}


struct MoveEntry: Identifiable, Equatable {
    let name: String
    
    // e.g. "level-up", "machine", "egg", "tutor"
    let learnMethod: String     
    
    let levelLearnedAt: Int
    let versionGroup: String

    var id: String { "\(name)-\(versionGroup)-\(learnMethod)-\(levelLearnedAt)" }

    var displayName: String { name.capitalizedWords }

    var isLevelUp: Bool { learnMethod == "level-up" }

    var isMachine: Bool { learnMethod == "machine" }
}


struct PokemonSpeciesInfo: Equatable {
    let id: Int
    let isLegendary: Bool
    let isMythical: Bool
    
    // -1 genderless, 0 always male, 8 always female, 1-7 mixed
    let genderRate: Int
    let evolutionChainId: Int?
    let generationName: String?

    var isGenderless: Bool { genderRate < 0 }
    var isMaleOnly: Bool { genderRate == 0 }
    var isFemaleOnly: Bool { genderRate == 8 }

    var hasSingleGender: Bool { isGenderless || isMaleOnly || isFemaleOnly }
}


struct PokemonDetail: Identifiable, Equatable {
    let id: Int
    let name: String
    let types: [String]
    
    // decimeters
    let height: Int
    
    // hectograms
    let weight: Int
    let stats: [StatValue]
    let abilities: [AbilityEntry]
    let moves: [MoveEntry]
    let sprites: SpriteSet

    var displayName: String { name.pokemonDisplayName }

    var generation: Int { Constants.Generations.generation(for: id) ?? 0 }

    var region: String { Constants.Generations.region(for: id) ?? "Unknown" }

    var subtitle: String { "\(id.pokedexNumber) - Generation \(generation) - \(region)" }

    var heightLabel: String { height.heightLabel }

    var weightLabel: String { weight.weightLabel }

    // HP/Atk/Def/SpA/SpD/Spe order
    var orderedStats: [StatValue] {
        Constants.Stats.order.compactMap { key in stats.first { $0.key == key } }
    }

    var summary: PokemonSummary {
        PokemonSummary(id: id, name: name, types: types)
    }

    var moveVersionGroups: [String] {
        Array(Set(moves.map(\.versionGroup))).sorted()
    }
}
