import Foundation


struct NamedResourceDTO: Codable {
    let name: String?
    let url: String?

    var resourceId: Int? {
        guard let url else { return nil }
        return url.split(separator: "/").compactMap { Int($0) }.last
    }
}

// MARK: - /pokemon?limit=

struct PokemonIndexDTO: Codable {
    let count: Int?
    let results: [NamedResourceDTO]?
}

// MARK: - /pokemon/{id}

struct PokemonDTO: Codable {
    let id: Int?
    let name: String?
    let height: Int?
    let weight: Int?
    let types: [TypeSlotDTO]?
    let stats: [StatSlotDTO]?
    let abilities: [AbilitySlotDTO]?
    let moves: [MoveSlotDTO]?
    let sprites: SpritesDTO?

    struct TypeSlotDTO: Codable {
        let slot: Int?
        let type: NamedResourceDTO?
    }

    struct StatSlotDTO: Codable {
        let baseStat: Int?
        let stat: NamedResourceDTO?
    }

    struct AbilitySlotDTO: Codable {
        let isHidden: Bool?
        let slot: Int?
        let ability: NamedResourceDTO?
    }

    struct MoveSlotDTO: Codable {
        let move: NamedResourceDTO?
        let versionGroupDetails: [VersionGroupDetailDTO]?

        struct VersionGroupDetailDTO: Codable {
            let levelLearnedAt: Int?
            let moveLearnMethod: NamedResourceDTO?
            let versionGroup: NamedResourceDTO?
        }
    }

    struct SpritesDTO: Codable {
        let frontDefault: String?
        let frontShiny: String?
        let frontFemale: String?
        let frontShinyFemale: String?
        let backDefault: String?
        let backShiny: String?
        let backFemale: String?
        let backShinyFemale: String?
    }
}

// MARK: - /type/{name}

struct TypeDTO: Codable {
    let id: Int?
    let name: String?
    let damageRelations: DamageRelationsDTO?
    let pokemon: [TypePokemonDTO]?

    struct DamageRelationsDTO: Codable {
        let doubleDamageFrom: [NamedResourceDTO]?
        let halfDamageFrom: [NamedResourceDTO]?
        let noDamageFrom: [NamedResourceDTO]?
    }

    struct TypePokemonDTO: Codable {
        let slot: Int?
        let pokemon: NamedResourceDTO?
    }
}

// MARK: - /pokemon-species/{id}

struct SpeciesDTO: Codable {
    let id: Int?
    let name: String?
    let isLegendary: Bool?
    let isMythical: Bool?
    let genderRate: Int?
    let generation: NamedResourceDTO?
    let evolutionChain: EvolutionChainRefDTO?

    struct EvolutionChainRefDTO: Codable {
        let url: String?

        var chainId: Int? {
            guard let url else { return nil }
            return url.split(separator: "/").compactMap { Int($0) }.last
        }
    }
}

// MARK: - /evolution-chain/{id}

struct EvolutionChainDTO: Codable {
    let id: Int?
    let chain: ChainLinkDTO?

    /// each link holds the species it is and its evolution
    struct ChainLinkDTO: Codable {
        let species: NamedResourceDTO?
        let evolutionDetails: [EvolutionDetailDTO]?
        let evolvesTo: [ChainLinkDTO]?
    }

    struct EvolutionDetailDTO: Codable {
        let trigger: NamedResourceDTO?
        let minLevel: Int?
        let item: NamedResourceDTO?
        let heldItem: NamedResourceDTO?
        let knownMove: NamedResourceDTO?
        let knownMoveType: NamedResourceDTO?
        let location: NamedResourceDTO?
        let minHappiness: Int?
        let minBeauty: Int?
        let minAffection: Int?
        let needsOverworldRain: Bool?
        let partySpecies: NamedResourceDTO?
        let partyType: NamedResourceDTO?
        let relativePhysicalStats: Int?
        let timeOfDay: String?
        let tradeSpecies: NamedResourceDTO?
        let turnUpsideDown: Bool?
        let gender: Int?
    }
}

// MARK: - /pokemon/{id}/encounters

struct LocationAreaEncounterDTO: Codable {
    let locationArea: NamedResourceDTO?
    let versionDetails: [VersionDetailDTO]?

    struct VersionDetailDTO: Codable {
        let version: NamedResourceDTO?
        let maxChance: Int?
        let encounterDetails: [EncounterDetailDTO]?

        struct EncounterDetailDTO: Codable {
            let minLevel: Int?
            let maxLevel: Int?
            let chance: Int?
            let method: NamedResourceDTO?
        }
    }
}
