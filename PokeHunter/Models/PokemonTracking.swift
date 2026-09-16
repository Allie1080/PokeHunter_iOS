import Foundation

struct PokemonTracking: Identifiable, Codable, Equatable {
    var pokemonId: Int

    var isCaught: Bool {
        didSet { if !isCaught { isShinyCaught = false } }
    }

    var isShinyCaught: Bool {
        didSet { if isShinyCaught { isCaught = true } }
    }

    var notes: String?

    var id: Int { pokemonId }

    enum CodingKeys: String, CodingKey {
        case pokemonId
        case isCaught
        case isShinyCaught
        case notes
    }

    init(
        pokemonId: Int,
        isCaught: Bool = false,
        isShinyCaught: Bool = false,
        notes: String? = nil
    ) {
        self.pokemonId = pokemonId
        self.isCaught = isCaught || isShinyCaught
        self.isShinyCaught = isShinyCaught
        self.notes = notes
    }
}