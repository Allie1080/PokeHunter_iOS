import Foundation
import Combine
import SwiftUI

@MainActor
final class GalleryController: ObservableObject {

    @Published private(set) var visiblePokemon: [PokemonSummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // parsed on submit, not per typing
    @Published var searchText: String = ""
    @Published private(set) var searchError: String?

    @Published var selectedGenerations: Set<Int> = []
    @Published var showLegendaryOnly = false
    @Published var showMythicalOnly = false
    @Published var selectedTypes: Set<String> = []

    private var allPokemon: [PokemonSummary] = []
    private var query = SearchQuery()
    private var typeMembership: [String: Set<Int>] = [:]

    private let api = PokemonAPIWrapper.shared


    var generationLabel: String {
        if selectedGenerations.isEmpty { return "All" }
        let sorted = selectedGenerations.sorted()
        if sorted.count == 1 { return "Gen \(sorted[0])" }
        return "\(sorted.count) selected"
    }

    var typeFilterCount: Int { selectedTypes.count }

    var hasActiveFilters: Bool {
        !selectedGenerations.isEmpty
            || showLegendaryOnly
            || showMythicalOnly
            || !selectedTypes.isEmpty
            || !searchText.isEmpty
    }


    func loadIfNeeded() async {
        guard allPokemon.isEmpty, !isLoading else { return }
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            allPokemon = try await api.fetchIndex()
            await applyFilters()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func runSearch() async {
        do {
            query = try SearchParser.parse(searchText)
            searchError = nil
            await applyFilters()
        } catch let error as SearchParserError {
            searchError = Self.message(for: error)
        } catch {
            searchError = error.localizedDescription
        }
    }

    func clearSearch() async {
        searchText = ""
        query = SearchQuery()
        searchError = nil
        await applyFilters()
    }

    private static func message(for error: SearchParserError) -> String {
        switch error {
        case .emptyNameQuery:
            return "`name:` needs something after it, like `name:pika`."
        case .invalidGeneration(let token):
            return "`gen\(token)` isn't a generation. Try gen1–gen7."
        case .emptyTypeInAND:
            return "`+` needs a type on both sides, like `fire+water`."
        }
    }

    func toggleGeneration(_ generation: Int) async {
        if selectedGenerations.contains(generation) {
            selectedGenerations.remove(generation)
        } else {
            selectedGenerations.insert(generation)
        }
        await applyFilters()
    }

    func clearGenerations() async {
        selectedGenerations.removeAll()
        await applyFilters()
    }

    func applyTypeSelection(_ types: Set<String>) async {
        selectedTypes = types
        await applyFilters()
    }

    func resetAllFilters() async {
        selectedGenerations.removeAll()
        showLegendaryOnly = false
        showMythicalOnly = false
        selectedTypes.removeAll()
        searchText = ""
        searchError = nil
        query = SearchQuery()
        await applyFilters()
    }

    func applyFilters() async {
        guard !allPokemon.isEmpty else {
            visiblePokemon = []
            return
        }

        let typesNeeded = selectedTypes
            .union(query.anyOfTypes)
            .union(query.allOfTypes)
            .union(query.excludeTypes)

        await ensureTypeMembership(for: typesNeeded)

        var results = allPokemon

        if !selectedGenerations.isEmpty {
            results = results.filter { selectedGenerations.contains($0.generation) }
        }
        if !query.includeGenerations.isEmpty {
            results = results.filter { query.includeGenerations.contains($0.generation) }
        }
        if !query.excludeGenerations.isEmpty {
            results = results.filter { !query.excludeGenerations.contains($0.generation) }
        }
        if let min = query.generationRangeMin {
            results = results.filter { $0.generation >= min }
        }
        if let max = query.generationRangeMax {
            results = results.filter { $0.generation <= max }
        }

        if showLegendaryOnly && showMythicalOnly {
            results = results.filter { $0.isLegendary || $0.isMythical }
        } else if showLegendaryOnly {
            results = results.filter(\.isLegendary)
        } else if showMythicalOnly {
            results = results.filter(\.isMythical)
        }

        if query.onlyLegendary && query.onlyMythical {
            results = results.filter { $0.isLegendary || $0.isMythical }
        } else if query.onlyLegendary {
            results = results.filter(\.isLegendary)
        } else if query.onlyMythical {
            results = results.filter(\.isMythical)
        }

        if query.excludeLegendary {
            results = results.filter { !$0.isLegendary }
        }
        if query.excludeMythical {
            results = results.filter { !$0.isMythical }
        }

        if !selectedTypes.isEmpty {
            let allowed = union(of: selectedTypes)
            results = results.filter { allowed.contains($0.id) }
        }
        if !query.anyOfTypes.isEmpty {
            let allowed = union(of: Set(query.anyOfTypes))
            results = results.filter { allowed.contains($0.id) }
        }
        for type in query.allOfTypes {
            let members = typeMembership[type] ?? []
            results = results.filter { members.contains($0.id) }
        }
        for type in query.excludeTypes {
            let members = typeMembership[type] ?? []
            results = results.filter { !members.contains($0.id) }
        }

        if !query.nameQuery.isEmpty {
            let needle = query.nameQuery.lowercased()
            results = results.filter { $0.name.lowercased().contains(needle) }
        }

        visiblePokemon = results
    }

    private func union(of types: Set<String>) -> Set<Int> {
        types.reduce(into: Set<Int>()) { acc, type in
            acc.formUnion(typeMembership[type] ?? [])
        }
    }

    private func ensureTypeMembership(for types: Set<String>) async {
        for type in types where typeMembership[type] == nil {
            let ids = (try? await api.fetchPokemonIds(ofType: type)) ?? []
            typeMembership[type] = ids
        }
    }
}
