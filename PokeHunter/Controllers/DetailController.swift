import Foundation
import Combine
import SwiftUI


@MainActor
final class DetailController: ObservableObject {

    enum Tab: String, CaseIterable, Identifiable {
        case stats = "Stats"
        case moveset = "Moveset"
        case evolution = "Evolution"
        case notes = "Notes"

        var id: String { rawValue }
    }

    // MARK: - Published state

    @Published private(set) var detail: PokemonDetail?
    @Published private(set) var species: PokemonSpeciesInfo?
    @Published private(set) var effectiveness: TypeEffectiveness = .empty
    @Published private(set) var evolutionSteps: [EvolutionStep] = []
    @Published private(set) var alternateEvolutionSteps: [EvolutionStep] = []

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published var selectedTab: Tab = .stats

    // isShiny starts false but is re-rolled on load, see Constants.Sprites
    @Published private(set) var isShowingBack = false
    @Published var isFemale = false
    @Published var isShiny = false


    @Published private(set) var tracking: PokemonTracking
    @Published var notesDraft: String = ""

    @Published var selectedVersionGroup: String?

    let pokemonId: Int

    private let api = PokemonAPIWrapper.shared
    private let typeService = TypeEffectivenessService.shared
    private let database: DatabaseService

    init(pokemonId: Int, database: DatabaseService = .shared) {
        self.pokemonId = pokemonId
        self.database = database
        self.tracking = (try? database.tracking(for: pokemonId))
            ?? PokemonTracking(pokemonId: pokemonId)
        self.notesDraft = tracking.notes ?? ""

    }

    // toggle is hidden when no female sprite
    var showsGenderToggle: Bool {
        detail?.sprites.hasFemaleSprite ?? false
    }

    // visible but disabled for a species with only one gender
    var isGenderToggleEnabled: Bool {
        guard let species else { return false }
        return !species.hasSingleGender
    }

    var currentSpriteURL: URL? {
        detail?.sprites.url(front: !isShowingBack, shiny: isShiny, female: isFemale)
    }

    func flipSprite() {
        withAnimation(.easeInOut(duration: 0.35)) {
            isShowingBack.toggle()
        }
    }


    func load() async {
        guard detail == nil, !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let detail = try await api.fetchDetail(id: pokemonId)

            // rolled before the first render, so a lucky sprite is shiny from the outset rather than flicking over a frame later
            // tapping the name still toggles from wherever it landed.
            self.isShiny = Constants.Sprites.rollsShiny

            self.detail = detail
            self.selectedVersionGroup = Self.defaultVersionGroup(from: detail)

            // independent of each other, so a slow one doesn't hold up the rest of the screen
            async let speciesTask = api.fetchSpecies(id: pokemonId)
            async let effectivenessTask = typeService.effectiveness(for: detail.types)

            let species = try? await speciesTask
            self.species = species
            applyDefaultGender(for: species)

            self.effectiveness = (try? await effectivenessTask) ?? .empty

            await loadEvolution(chainId: species?.evolutionChainId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyDefaultGender(for species: PokemonSpeciesInfo?) {
        isFemale = species?.isFemaleOnly ?? false
    }

    private func loadEvolution(chainId: Int?) async {
        guard let chainId else { return }
        guard let chain = try? await api.fetchEvolutionChain(id: chainId) else { return }

        let steps = EvolutionFormatter.steps(from: chain)
        evolutionSteps = EvolutionFormatter.primarySteps(from: steps)
        alternateEvolutionSteps = EvolutionFormatter.alternateSteps(from: steps)
    }


    /// returns nil for groups outside gen1-7, which the app doesn't cover.
    static func generation(ofVersionGroup group: String) -> Int? {
        group
            .split(separator: "-")
            .compactMap { Self.generationsBySlug[String($0)] }
            .max()
    }

    private static let generationsBySlug = Dictionary(
        uniqueKeysWithValues: VersionCatalog.all.map { ($0.slug, $0.generation) }
    )

    /// prefer a version group the app actually covers (gen1-7), newest first
    private static func defaultVersionGroup(from detail: PokemonDetail) -> String? {
        let groups = detail.moveVersionGroups
        let ranked = groups.compactMap { group -> (group: String, generation: Int)? in
            generation(ofVersionGroup: group).map { (group, $0) }
        }
        return ranked.max { $0.generation < $1.generation }?.group ?? groups.last
    }

    var levelUpMoves: [MoveEntry] {
        guard let group = selectedVersionGroup else { return [] }
        return (detail?.moves ?? [])
            .filter { $0.versionGroup == group && $0.isLevelUp }
            .sorted { ($0.levelLearnedAt, $0.name) < ($1.levelLearnedAt, $1.name) }
    }

    var machineMoves: [MoveEntry] {
        guard let group = selectedVersionGroup else { return [] }
        return (detail?.moves ?? [])
            .filter { $0.versionGroup == group && $0.isMachine }
            .sorted { $0.name < $1.name }
    }

    // ordered by generation, groups the app doesn't cover sort last
    var availableVersionGroups: [String] {
        (detail?.moveVersionGroups ?? []).sorted { lhs, rhs in
            let lhsGen = Self.generation(ofVersionGroup: lhs) ?? Int.max
            let rhsGen = Self.generation(ofVersionGroup: rhs) ?? Int.max
            return lhsGen == rhsGen ? lhs < rhs : lhsGen < rhsGen
        }
    }


    func setCaught(_ value: Bool) {
        tracking.isCaught = value
        persistTracking()
    }

    func setShinyCaught(_ value: Bool) {
        tracking.isShinyCaught = value
        persistTracking()
    }

    /// called when the Notes tab loses focus, not on every typing
    func commitNotes() {
        let trimmed = notesDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        tracking.notes = trimmed.isEmpty ? nil : trimmed
        persistTracking()
    }

    private func persistTracking() {
        do {
            try database.save(tracking)
        } catch {
            errorMessage = "Couldn't save your changes."
        }
    }
}
