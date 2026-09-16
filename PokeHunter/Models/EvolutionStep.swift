import Foundation

struct EvolutionStep: Identifiable, Equatable {
    /// level-up > stone > trade > happiness > other.
    enum Trigger: Int, Comparable {
        case levelUp = 0
        case stone = 1
        case trade = 2
        case happiness = 3
        case other = 4

        static func < (lhs: Trigger, rhs: Trigger) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    let fromId: Int
    let fromName: String
    let toId: Int
    let toName: String
    let trigger: Trigger
    
    // e.g. "level 16" or "use water stone"
    let condition: String

    var id: String { "\(fromId)-\(toId)-\(condition)" }

    var fromDisplayName: String { fromName.pokemonDisplayName }

    var toDisplayName: String { toName.pokemonDisplayName }
}
