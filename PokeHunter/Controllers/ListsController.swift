import Foundation
import Combine
import SwiftUI
import GRDB

@MainActor
final class ListsController: ObservableObject {

    @Published private(set) var customLists: [PokemonList] = []
    @Published private(set) var tracking: [PokemonTracking] = []
    @Published private(set) var listCounts: [UUID: Int] = [:]
    @Published private(set) var errorMessage: String?

    private let database: DatabaseService
    private var trackingObserver: DatabaseCancellable?
    private var listsObserver: DatabaseCancellable?

    init(database: DatabaseService = .shared) {
        self.database = database
        startObserving()
    }

    var regularCaught: [Int] {
        tracking
            .filter { $0.isCaught && !$0.isShinyCaught }
            .map(\.pokemonId)
            .sorted()
    }

    var shinyCaught: [Int] {
        tracking
            .filter(\.isShinyCaught)
            .map(\.pokemonId)
            .sorted()
    }

    // MARK: - badges for the Gallery grid

    func isCaught(_ pokemonId: Int) -> Bool {
        tracking.first { $0.pokemonId == pokemonId }?.isCaught ?? false
    }

    func isShinyCaught(_ pokemonId: Int) -> Bool {
        tracking.first { $0.pokemonId == pokemonId }?.isShinyCaught ?? false
    }


    private func startObserving() {
        trackingObserver = database.observeTracking { [weak self] rows in
            self?.tracking = rows
        }
        listsObserver = database.observeLists { [weak self] lists in
            guard let self else { return }
            self.customLists = lists
            self.refreshCounts()
        }
    }

    func refresh() {
        do {
            tracking = try database.allTracking()
            customLists = try database.allLists()
            refreshCounts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshCounts() {
        listCounts = (try? database.counts(forLists: customLists.map(\.id))) ?? [:]
    }

    func count(for list: PokemonList) -> Int {
        listCounts[list.id] ?? 0
    }


    @discardableResult
    func createList(named name: String) -> PokemonList? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        do {
            let list = try database.createList(named: trimmed)
            refresh()
            return list
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func rename(_ list: PokemonList, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        perform { try database.rename(listId: list.id, to: trimmed) }
    }

    func delete(_ list: PokemonList) {
        perform { try database.deleteList(id: list.id) }
    }

    func delete(atOffsets offsets: IndexSet) {
        let targets = offsets.map { customLists[$0] }
        perform {
            for list in targets {
                try database.deleteList(id: list.id)
            }
        }
    }


    func pokemonIds(in list: PokemonList) -> [Int] {
        (try? database.pokemonIds(inList: list.id)) ?? []
    }

    func add(_ pokemonId: Int, to list: PokemonList) {
        perform { try database.addPokemon(pokemonId, toList: list.id) }
    }

    func remove(_ pokemonId: Int, from list: PokemonList) {
        perform { try database.removePokemon(pokemonId, fromList: list.id) }
    }

    func listIds(containing pokemonId: Int) -> Set<UUID> {
        (try? database.listIds(containing: pokemonId)) ?? []
    }

    func setMembership(pokemonId: Int, listIds selected: Set<UUID>) {
        let current = listIds(containing: pokemonId)

        perform {
            for id in selected.subtracting(current) {
                try database.addPokemon(pokemonId, toList: id)
            }
            for id in current.subtracting(selected) {
                try database.removePokemon(pokemonId, fromList: id)
            }
        }
    }


    private func perform(_ work: () throws -> Void) {
        do {
            try work()
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
