import Foundation

enum TypeCatalog {
    static let all = [
        "normal", "fire", "water", "electric", "grass", "ice",
        "fighting", "poison", "ground", "flying", "psychic", "bug",
        "rock", "ghost", "dragon", "dark", "steel", "fairy",
    ]

    private static let lookup = Set(all)

    static func isType(_ candidate: String) -> Bool {
        lookup.contains(candidate.lowercased())
    }
}
