import Foundation

struct PokemonListEntry: Identifiable, Codable, Equatable {
    var listId: UUID
    var pokemonId: Int
    var dateAdded: Date

    var id: String { "\(listId.uuidString)-\(pokemonId)" }

    enum CodingKeys: String, CodingKey {
        case listId
        case pokemonId
        case dateAdded
    }

    init(listId: UUID, pokemonId: Int, dateAdded: Date = Date()) {
        self.listId = listId
        self.pokemonId = pokemonId
        self.dateAdded = dateAdded
    }
}