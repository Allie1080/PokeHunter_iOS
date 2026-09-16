#if canImport(GRDB)
import GRDB


extension PokemonTracking: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "pokemonTracking"

    enum Columns {
        static let pokemonId     = Column(CodingKeys.pokemonId)
        static let isCaught      = Column(CodingKeys.isCaught)
        static let isShinyCaught = Column(CodingKeys.isShinyCaught)
        static let notes         = Column(CodingKeys.notes)
    }
}


extension PokemonList: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "pokemonList"

    enum Columns {
        static let id        = Column(CodingKeys.id)
        static let name      = Column(CodingKeys.name)
        static let createdAt = Column(CodingKeys.createdAt)
    }
}


extension PokemonListEntry: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "pokemonListEntry"

    enum Columns {
        static let listId    = Column(CodingKeys.listId)
        static let pokemonId = Column(CodingKeys.pokemonId)
        static let dateAdded = Column(CodingKeys.dateAdded)
    }
}
#endif

