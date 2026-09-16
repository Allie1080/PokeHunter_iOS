import SwiftUI

struct DetailView: View {

    @StateObject private var controller: DetailController
    @EnvironmentObject private var lists: ListsController

    @State private var isShowingAddToList = false
    @State private var isBookmarked = false
    @FocusState private var isNotesFocused: Bool

    init(pokemonId: Int) {
        _controller = StateObject(wrappedValue: DetailController(pokemonId: pokemonId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let detail = controller.detail {
                    ProfileSection(controller: controller, detail: detail)
                    OverviewSection(detail: detail)
                    TrackingSection(controller: controller)
                    actionButtons(for: detail)
                    detailsTabs(for: detail)
                } else if controller.isLoading {
                    ProgressView("Loading…")
                        .padding(.vertical, 80)
                } else if let errorMessage = controller.errorMessage {
                    EmptyStateView(
                        systemImage: "wifi.exclamationmark",
                        title: "Couldn't load this Pokémon",
                        message: errorMessage,
                        actionTitle: "Try again",
                        action: { Task { await controller.load() } }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle(controller.detail?.displayName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAddToList = true
                } label: {
                    Label(
                        isBookmarked ? "Edit lists" : "Add to Lists",
                        systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                    )
                }
            }
        }
        .task { await controller.load() }
        .task(id: lists.customLists.count) { refreshBookmarkState() }
        .sheet(isPresented: $isShowingAddToList, onDismiss: refreshBookmarkState) {
            AddToListModal(pokemonId: controller.pokemonId)
                .environmentObject(lists)
        }
    }

    private func refreshBookmarkState() {
        isBookmarked = !lists.listIds(containing: controller.pokemonId).isEmpty
    }

    // MARK: - Actions

    @ViewBuilder
    private func actionButtons(for detail: PokemonDetail) -> some View {
        NavigationLink(value: Route.encounter(pokemonId: detail.id)) {
            Label("Hunt this Pokémon", systemImage: "map.fill")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
    }

    // MARK: - Details tabs

    @ViewBuilder
    private func detailsTabs(for detail: PokemonDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            Picker("Details", selection: $controller.selectedTab) {
                ForEach(DetailController.Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            switch controller.selectedTab {
            case .stats:
                StatsTab(detail: detail, effectiveness: controller.effectiveness)
            case .moveset:
                MovesetTab(controller: controller, detail: detail)
            case .evolution:
                EvolutionTab(controller: controller)
            case .notes:
                NotesTab(controller: controller, isFocused: $isNotesFocused)
            }
        }
    }
}

// MARK: - Profile

/// Sprite stage plus name, Pokédex line and types.
private struct ProfileSection: View {

    @ObservedObject var controller: DetailController
    let detail: PokemonDetail

    var body: some View {
        VStack(spacing: 12) {
            spriteStage

            VStack(spacing: 4) {
                // The sprite itself is the shiny indicator — no marker beside
                // the name.
                Text(detail.displayName)
                    .font(.title.bold())
                    .contentShape(Rectangle())
                    .onTapGesture { controller.isShiny.toggle() }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(detail.displayName)
                .accessibilityValue(controller.isShiny ? "Shiny" : "Normal")
                .accessibilityHint("Double-tap to switch between normal and shiny")
                .accessibilityAddTraits(.isButton)

                Text(detail.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(detail.types, id: \.self) { type in
                    TypeChip(type: type)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    /// Tap the sprite to flip between front and back; the gender toggle sits over
    /// it rather than in the Tracking section (plan §9). Shiny is toggled by
    /// tapping the name.
    private var spriteStage: some View {
        ZStack(alignment: .topTrailing) {
            SpriteImage(url: controller.currentSpriteURL, size: 180)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground), in: Circle())
                // Pre-mirror the back sprite so the 180° turn lands it facing
                // the right way instead of reversed.
                .scaleEffect(x: controller.isShowingBack ? -1 : 1, y: 1)
                .rotation3DEffect(
                    .degrees(controller.isShowingBack ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .onTapGesture { controller.flipSprite() }
                .accessibilityLabel(controller.isShowingBack ? "Back sprite" : "Front sprite")
                .accessibilityHint("Double-tap to flip")

            if controller.showsGenderToggle {
                genderToggle
                    .padding(.trailing, 8)
            }
        }
    }

    /// Visible but disabled for a single-gender species, so the reason there is
    /// nothing to switch stays obvious.
    private var genderToggle: some View {
        HStack(spacing: 0) {
            genderButton(female: false, symbol: "♂", tint: Color(hex: "4A90D9"))
            genderButton(female: true, symbol: "♀", tint: Color(hex: "E57BA1"))
        }
        .background(.thinMaterial, in: Capsule())
        .opacity(controller.isGenderToggleEnabled ? 1 : 0.45)
        .disabled(!controller.isGenderToggleEnabled)
    }

    private func genderButton(female: Bool, symbol: String, tint: Color) -> some View {
        let isSelected = controller.isFemale == female
        return Button {
            controller.isFemale = female
        } label: {
            Text(symbol)
                .font(.headline)
                .foregroundStyle(isSelected ? tint : Color.secondary)
                .frame(width: 34, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(female ? "Female sprite" : "Male sprite")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Overview

/// Height and weight only (plan §9).
private struct OverviewSection: View {
    let detail: PokemonDetail

    var body: some View {
        GroupedCard(title: "Overview") {
            LabeledRow(title: "Height", value: detail.heightLabel)
            Divider().padding(.leading, 16)
            LabeledRow(title: "Weight", value: detail.weightLabel)
        }
    }
}

// MARK: - Tracking

/// Two booleans, no date. Shiny implies caught — the invariant lives in
/// `PokemonTracking`, so ticking Shiny here ticks Caught too.
private struct TrackingSection: View {
    @ObservedObject var controller: DetailController

    var body: some View {
        GroupedCard(title: "Tracking") {
            Toggle("Caught", isOn: Binding(
                get: { controller.tracking.isCaught },
                set: { controller.setCaught($0) }
            ))
            .tint(Color.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider().padding(.leading, 16)

            Toggle("Shiny Caught", isOn: Binding(
                get: { controller.tracking.isShinyCaught },
                set: { controller.setShinyCaught($0) }
            ))
            .tint(Color.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Stats tab

private struct StatsTab: View {
    let detail: PokemonDetail
    let effectiveness: TypeEffectiveness

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupedCard(title: "Stats") {
                VStack(spacing: 10) {
                    ForEach(detail.orderedStats) { stat in
                        StatBar(name: stat.displayName, value: stat.value)
                    }
                }
                .padding(16)
            }

            Text(Constants.Copy.statsDisclaimer)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !effectiveness.weaknesses.isEmpty {
                matchupCard(title: "Weaknesses", matchups: effectiveness.weaknesses)
            }
            if !effectiveness.resistances.isEmpty {
                matchupCard(title: "Resistance", matchups: effectiveness.resistances)
            }
            if !effectiveness.immunities.isEmpty {
                matchupCard(title: "Immunities", matchups: effectiveness.immunities)
            }
        }
    }

    private func matchupCard(title: String, matchups: [TypeMatchup]) -> some View {
        GroupedCard(title: title) {
            ForEach(Array(matchups.enumerated()), id: \.element.id) { index, matchup in
                if index > 0 { Divider().padding(.leading, 16) }
                HStack {
                    TypeChip(type: matchup.type, size: .small)
                    Spacer()
                    Text(matchup.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }
}

/// One base stat, as a proportion of the highest base stat in the games.
private struct StatBar: View {
    let name: String
    let value: Int

    var body: some View {
        HStack(spacing: 10) {
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 58, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                    Capsule()
                        .fill(color)
                        .frame(
                            width: geo.size.width
                                * CGFloat(value)
                                / CGFloat(Constants.Stats.maxBaseStat)
                        )
                }
            }
            .frame(height: 8)

            Text("\(value)")
                .font(.caption.monospacedDigit())
                .frame(width: 32, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name) \(value)")
    }

    private var color: Color {
        switch value {
        case ..<50:    return Color(hex: "E53935")
        case 50..<90:  return Color(hex: "FB8C00")
        case 90..<120: return Color(hex: "FDD835")
        case 120..<160: return Color(hex: "43A047")
        default:       return Color(hex: "1E88E5")
        }
    }
}

// MARK: - Moveset tab

private struct MovesetTab: View {
    @ObservedObject var controller: DetailController
    let detail: PokemonDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if controller.availableVersionGroups.isEmpty {
                EmptyStateView(systemImage: "list.bullet", title: "No move data")
            } else {
                GroupedCard(title: "Game") {
                    HStack {
                        Text("Game")
                        Spacer()
                        Picker("Game", selection: $controller.selectedVersionGroup) {
                            ForEach(controller.availableVersionGroups, id: \.self) { group in
                                Text(VersionCatalog.displayName(forVersionGroup: group))
                                    .tag(group as String?)
                            }
                        }
                        .labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                if !controller.levelUpMoves.isEmpty {
                    GroupedCard(title: "Level-Up Moves") {
                        ForEach(Array(controller.levelUpMoves.enumerated()), id: \.element.id) { index, move in
                            if index > 0 { Divider().padding(.leading, 16) }
                            LabeledRow(title: move.displayName, value: "Lvl. \(move.levelLearnedAt)")
                        }
                    }
                }

                if !controller.machineMoves.isEmpty {
                    GroupedCard(title: "TM & HM Moves") {
                        ForEach(Array(controller.machineMoves.enumerated()), id: \.element.id) { index, move in
                            if index > 0 { Divider().padding(.leading, 16) }
                            LabeledRow(title: move.displayName, value: "TM")
                        }
                    }
                }
            }

            if !detail.abilities.isEmpty {
                GroupedCard(title: "Abilities") {
                    ForEach(Array(detail.abilities.enumerated()), id: \.element.id) { index, ability in
                        if index > 0 { Divider().padding(.leading, 16) }
                        LabeledRow(
                            title: ability.displayName,
                            value: ability.isHidden ? "Hidden" : ""
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Evolution tab

/// Vertical chain. Condition priority is level-up → stone → trade → happiness →
/// other; anything the priority pass didn't pick is listed separately (plan §9).
private struct EvolutionTab: View {
    @ObservedObject var controller: DetailController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if controller.evolutionSteps.isEmpty {
                EmptyStateView(
                    systemImage: "arrow.triangle.branch",
                    title: "This Pokémon doesn't evolve"
                )
            } else {
                GroupedCard(title: "Evolution Chart") {
                    VStack(spacing: 4) {
                        ForEach(Array(controller.evolutionSteps.enumerated()), id: \.element.id) { index, step in
                            if index == 0 {
                                stage(id: step.fromId, name: step.fromDisplayName)
                            }
                            arrow(condition: step.condition)
                            stage(id: step.toId, name: step.toDisplayName)
                        }
                    }
                    .padding(16)
                }

                if !controller.alternateEvolutionSteps.isEmpty {
                    GroupedCard(title: "Alternate Methods") {
                        ForEach(Array(controller.alternateEvolutionSteps.enumerated()), id: \.element.id) { index, step in
                            if index > 0 { Divider().padding(.leading, 16) }
                            LabeledRow(title: step.toDisplayName, value: step.condition)
                        }
                    }
                }
            }
        }
    }

    private func stage(id: Int, name: String) -> some View {
        NavigationLink(value: Route.detail(pokemonId: id)) {
            HStack(spacing: 12) {
                SpriteImage(url: Constants.API.spriteURL(for: id), size: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(id.pokedexNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(8)
            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func arrow(condition: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .frame(width: 56)
            Text(condition)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Notes tab

private struct NotesTab: View {
    @ObservedObject var controller: DetailController
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        GroupedCard(title: "Notes") {
            TextEditor(text: $controller.notesDraft)
                .frame(minHeight: 160)
                .padding(8)
                .focused($isFocused)
                .overlay(alignment: .topLeading) {
                    if controller.notesDraft.isEmpty {
                        Text("Notes…")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
        }
        // Saving per keystroke would hit SQLite on every letter.
        .onChange(of: isFocused) { _, focused in
            if !focused { controller.commitNotes() }
        }
        .onDisappear { controller.commitNotes() }
    }
}

// MARK: - Shared layout bits

/// The grouped-table look the design uses throughout: a titled rounded card.
private struct GroupedCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            VStack(spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LabeledRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            if !value.isEmpty {
                Text(value)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        DetailView(pokemonId: 1)
            .withPokeHunterDestinations()
    }
    .environmentObject(ListsController())
}
