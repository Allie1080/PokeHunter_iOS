import Foundation

struct PokemonList: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt
    }

    init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}