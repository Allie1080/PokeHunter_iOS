import Foundation
import Combine
import SwiftUI

@MainActor
final class EncounterController: ObservableObject {

    @Published private(set) var groups: [EncounterGroup] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // rest is greyed out by the picker
    @Published private(set) var availableVersions: Set<String> = []

    @Published var selectedVersion: GameVersion {
        didSet {
            guard selectedVersion != oldValue else { return }
            Task { await loadEncounters() }
        }
    }

    // the profile header repeats the Detail screen's, so the screen needs the full record
    // it comes out of the wrapper's cache after Detail has loaded it
    @Published private(set) var detail: PokemonDetail?

    let pokemonId: Int

    private let api = PokemonAPIWrapper.shared

    init(pokemonId: Int, initialVersion: GameVersion? = nil) {
        self.pokemonId = pokemonId

        let generation = Constants.Generations.generation(for: pokemonId) ?? 1
        self.selectedVersion = initialVersion
            ?? VersionCatalog.huntableByGeneration(generation).first
            ?? VersionCatalog.huntable[0]
    }

    /// Colosseum and XD excluded 
    var versionsByGeneration: [(generation: Int, versions: [GameVersion])] {
        Constants.Generations.supported.compactMap { generation in
            let versions = VersionCatalog.huntableByGeneration(generation)
            return versions.isEmpty ? nil : (generation, versions)
        }
    }

    func load() async {
        if detail == nil {
            detail = try? await api.fetchDetail(id: pokemonId)
        }
        await loadAvailability()
        await loadEncounters()
    }

    private func loadAvailability() async {
        availableVersions = (try? await api.fetchAvailableVersions(pokemonId: pokemonId)) ?? []
    }

    func loadEncounters() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let encounters = try await api.fetchEncounters(
                pokemonId: pokemonId,
                versionSlug: selectedVersion.slug
            )
            groups = Self.group(encounters)
        } catch {
            groups = []
            errorMessage = error.localizedDescription
        }
    }

    func isAvailable(_ version: GameVersion) -> Bool {
        // don't grey anything out before availability loads
        availableVersions.isEmpty || availableVersions.contains(version.slug)
    }

    private static func group(_ encounters: [EncounterDetail]) -> [EncounterGroup] {
        Dictionary(grouping: encounters, by: \.method)
            .map { method, entries in
                EncounterGroup(
                    method: method,
                    encounters: entries.sorted {
                        ($1.chance, $1.minLevel) < ($0.chance, $0.minLevel)
                    }
                )
            }
            .sorted { lhs, rhs in
                let lhsBest = lhs.encounters.first?.chance ?? 0
                let rhsBest = rhs.encounters.first?.chance ?? 0
                return lhsBest == rhsBest ? lhs.method < rhs.method : lhsBest > rhsBest
            }
    }
}
