import Foundation
import GRDB

final class DatabaseService: @unchecked Sendable {
    static let shared = DatabaseService()

    private let dbQueue: DatabaseQueue

    private init() {
        do {
            let folderURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dbURL = folderURL.appendingPathComponent("pokehunter.sqlite")
            dbQueue = try DatabaseQueue(path: dbURL.path)
            try Self.migrator.migrate(dbQueue)
        } catch {
            fatalError("Could not open the PokeHunter database: \(error)")
        }
    }

    init(inMemory: Bool) throws {
        dbQueue = try DatabaseQueue()
        try Self.migrator.migrate(dbQueue)
    }

    // MARK: - Schema

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initialSchema") { db in
            try db.create(table: "pokemonTracking") { t in
                t.column("pokemonId", .integer).primaryKey()
                t.column("isCaught", .boolean).notNull().defaults(to: false)
                t.column("isShinyCaught", .boolean).notNull().defaults(to: false)
                t.column("notes", .text)
            }

            try db.create(table: "pokemonList") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("createdAt", .datetime).notNull()
            }

            try db.create(table: "pokemonListEntry") { t in
                t.column("listId", .text)
                    .notNull()
                    .references("pokemonList", onDelete: .cascade)
                t.column("pokemonId", .integer).notNull()
                t.column("dateAdded", .datetime).notNull()
                // Composite key keeps a Pokémon from being added to one list twice.
                t.primaryKey(["listId", "pokemonId"])
            }
        }

        return migrator
    }


    func observeTracking(onChange: @escaping ([PokemonTracking]) -> Void) -> DatabaseCancellable {
        ValueObservation
            .tracking { db in try PokemonTracking.fetchAll(db) }
            .start(in: dbQueue, scheduling: .async(onQueue: .main),
                   onError: { _ in }, onChange: onChange)
    }

    func observeLists(onChange: @escaping ([PokemonList]) -> Void) -> DatabaseCancellable {
        ValueObservation
            .tracking { db in
                try PokemonList
                    .order(PokemonList.Columns.createdAt.desc)
                    .fetchAll(db)
            }
            .start(in: dbQueue, scheduling: .async(onQueue: .main),
                   onError: { _ in }, onChange: onChange)
    }


    func tracking(for pokemonId: Int) throws -> PokemonTracking {
        let stored = try dbQueue.read { db in
            try PokemonTracking.fetchOne(db, key: pokemonId)
        }
        return stored ?? PokemonTracking(pokemonId: pokemonId)
    }

    func allTracking() throws -> [PokemonTracking] {
        try dbQueue.read { db in try PokemonTracking.fetchAll(db) }
    }

    func save(_ tracking: PokemonTracking) throws {
        var record = tracking
        let isDefault = !record.isCaught
            && !record.isShinyCaught
            && (record.notes?.isEmpty ?? true)

        try dbQueue.write { db in
            if isDefault {
                _ = try PokemonTracking.deleteOne(db, key: record.pokemonId)
            } else {
                try record.save(db)
            }
        }
    }

    func setCaught(_ isCaught: Bool, for pokemonId: Int) throws {
        var record = try tracking(for: pokemonId)
        record.isCaught = isCaught          
        try save(record)
    }

    func setShinyCaught(_ isShinyCaught: Bool, for pokemonId: Int) throws {
        var record = try tracking(for: pokemonId)
        record.isShinyCaught = isShinyCaught 
        try save(record)
    }

    func setNotes(_ notes: String?, for pokemonId: Int) throws {
        var record = try tracking(for: pokemonId)
        record.notes = (notes?.isEmpty ?? true) ? nil : notes
        try save(record)
    }

    func allLists() throws -> [PokemonList] {
        try dbQueue.read { db in
            try PokemonList
                .order(PokemonList.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }

    @discardableResult
    func createList(named name: String) throws -> PokemonList {
        var list = PokemonList(name: name)
        try dbQueue.write { db in try list.insert(db) }
        return list
    }

    func rename(listId: UUID, to name: String) throws {
        try dbQueue.write { db in
            guard var list = try PokemonList.fetchOne(db, key: listId) else { return }
            list.name = name
            try list.update(db)
        }
    }

    func deleteList(id: UUID) throws {
        _ = try dbQueue.write { db in
            try PokemonList.deleteOne(db, key: id)
        }
    }


    func pokemonIds(inList listId: UUID) throws -> [Int] {
        try dbQueue.read { db in
            try PokemonListEntry
                .filter(PokemonListEntry.Columns.listId == listId)
                .order(PokemonListEntry.Columns.dateAdded.asc)
                .fetchAll(db)
                .map(\.pokemonId)
        }
    }

    func counts(forLists listIds: [UUID]) throws -> [UUID: Int] {
        guard !listIds.isEmpty else { return [:] }

        return try dbQueue.read { db in
            var counts: [UUID: Int] = [:]
            for listId in listIds {
                counts[listId] = try PokemonListEntry
                    .filter(PokemonListEntry.Columns.listId == listId)
                    .fetchCount(db)
            }
            return counts
        }
    }

    func addPokemon(_ pokemonId: Int, toList listId: UUID) throws {
        var entry = PokemonListEntry(listId: listId, pokemonId: pokemonId)
        try dbQueue.write { db in
            try entry.insert(db, onConflict: .ignore)
        }
    }

    func removePokemon(_ pokemonId: Int, fromList listId: UUID) throws {
        _ = try dbQueue.write { db in
            try PokemonListEntry
                .filter(PokemonListEntry.Columns.listId == listId)
                .filter(PokemonListEntry.Columns.pokemonId == pokemonId)
                .deleteAll(db)
        }
    }

    func listIds(containing pokemonId: Int) throws -> Set<UUID> {
        try dbQueue.read { db in
            let entries = try PokemonListEntry
                .filter(PokemonListEntry.Columns.pokemonId == pokemonId)
                .fetchAll(db)
            return Set(entries.map(\.listId))
        }
    }
}
