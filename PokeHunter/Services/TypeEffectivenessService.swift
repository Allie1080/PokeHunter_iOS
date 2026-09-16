import Foundation

actor TypeEffectivenessService {
    static let shared = TypeEffectivenessService()

    private let api = PokemonAPIWrapper.shared
    private var cache: [String: TypeEffectiveness] = [:]

    private init() {}

    func effectiveness(for types: [String]) async throws -> TypeEffectiveness {
        let key = types.map { $0.lowercased() }.sorted().joined(separator: "/")
        if let cached = cache[key] { return cached }
        guard !types.isEmpty else { return .empty }

        var multipliers = Dictionary(
            uniqueKeysWithValues: Constants.PokemonTypes.all.map { ($0, 1.0) }
        )

        for defendingType in types {
            let relations = try await api.fetchDamageRelations(for: defendingType)
            for (attackingType, factor) in relations {
                multipliers[attackingType, default: 1.0] *= factor
            }
        }

        // neutral matchups not shown
        let matchups = multipliers
            .filter { $0.value != 1.0 }
            .map { TypeMatchup(type: $0.key, multiplier: $0.value) }

        let result = TypeEffectiveness(matchups: matchups)
        cache[key] = result
        return result
    }
}
