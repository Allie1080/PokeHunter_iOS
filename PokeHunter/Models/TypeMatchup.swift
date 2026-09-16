import Foundation

struct TypeMatchup: Identifiable, Equatable {
    let type: String
    let multiplier: Double

    var id: String { type }

    var displayName: String { type.capitalizedWords }

    var label: String { multiplier.multiplierLabel }

    var isWeakness: Bool { multiplier > 1 }
    var isResistance: Bool { multiplier < 1 && multiplier > 0 }
    var isImmunity: Bool { multiplier == 0 }
}

struct TypeEffectiveness: Equatable {
    let matchups: [TypeMatchup]

    var weaknesses: [TypeMatchup] {
        matchups.filter(\.isWeakness).sorted { $0.multiplier > $1.multiplier }
    }

    var resistances: [TypeMatchup] {
        matchups.filter(\.isResistance).sorted { $0.multiplier < $1.multiplier }
    }

    var immunities: [TypeMatchup] {
        matchups.filter(\.isImmunity).sorted { $0.type < $1.type }
    }

    static let empty = TypeEffectiveness(matchups: [])
}
