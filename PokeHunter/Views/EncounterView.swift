import SwiftUI

struct EncounterView: View {

    @StateObject private var controller: EncounterController

    init(pokemonId: Int) {
        _controller = StateObject(wrappedValue: EncounterController(pokemonId: pokemonId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let detail = controller.detail {
                    profile(for: detail)
                    overview(for: detail)
                }

                gamePicker
                encounterContent
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Encounters")
        .navigationBarTitleDisplayMode(.inline)
        .task { await controller.load() }
    }

    // MARK: - Header

    private func profile(for detail: PokemonDetail) -> some View {
        VStack(spacing: 10) {
            SpriteImage(url: detail.sprites.frontDefault, size: 120)
                .background(Color(.secondarySystemBackground), in: Circle())

            VStack(spacing: 4) {
                Text(detail.displayName)
                    .font(.title2.bold())
                Text(detail.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(detail.types, id: \.self) { type in
                    TypeChip(type: type, size: .small)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func overview(for detail: PokemonDetail) -> some View {
        EncounterCard(title: "Overview") {
            HStack {
                Text("Height")
                Spacer()
                Text(detail.heightLabel).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.leading, 16)

            HStack {
                Text("Weight")
                Spacer()
                Text(detail.weightLabel).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // actually a Menu instead of a Picker cause a Picker can't disable individual options
    private var gamePicker: some View {
        EncounterCard(title: "Game") {
            Menu {
                ForEach(controller.versionsByGeneration, id: \.generation) { group in
                    Section("Generation \(group.generation)") {
                        ForEach(group.versions) { version in
                            Button {
                                controller.selectedVersion = version
                            } label: {
                                if version == controller.selectedVersion {
                                    Label(version.display, systemImage: "checkmark")
                                } else {
                                    Text(version.display)
                                }
                            }
                            // Greyed out when this Pokémon can't be found there.
                            .disabled(!controller.isAvailable(version))
                        }
                    }
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("Game")
                        .foregroundStyle(.primary)
                        .layoutPriority(1)

                    Spacer(minLength: 0)

                    // Long names wrap instead of truncating or squeezing the label.
                    Text(controller.selectedVersion.display)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Game")
            .accessibilityValue(controller.selectedVersion.display)
        }
    }

    // MARK: - Encounters

    @ViewBuilder
    private var encounterContent: some View {
        if controller.isLoading {
            ProgressView("Looking…")
                .padding(.vertical, 40)

        } else if let errorMessage = controller.errorMessage {
            EmptyStateView(
                systemImage: "wifi.exclamationmark",
                title: "Couldn't load encounters",
                message: errorMessage,
                actionTitle: "Try again",
                action: { Task { await controller.loadEncounters() } }
            )

        } else if controller.groups.isEmpty {
            EmptyStateView(
                systemImage: "binoculars",
                title: "Not found in \(controller.selectedVersion.display)",
                message: "This Pokémon can't be caught in the wild here — try another game, "
                    + "or check if it only arrives by trade or evolution."
            )

        } else {
            ForEach(controller.groups) { group in
                EncounterCard(
                    title: group.displayName,
                    accent: Constants.EncounterMethods.color(for: group.method)
                ) {
                    ForEach(Array(group.encounters.enumerated()), id: \.element.id) { index, encounter in
                        if index > 0 { Divider().padding(.leading, 16) }
                        EncounterRow(encounter: encounter)
                    }
                }
            }
        }
    }
}

// MARK: - Rows

private struct EncounterRow: View {
    let encounter: EncounterDetail

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(encounter.locationDisplayName)
                    .foregroundStyle(.primary)
                Text(encounter.levelLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if encounter.chance > 0 {
                Text(encounter.chanceLabel)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

/// Grouped card whose title carries the method's colour (plan §10).
private struct EncounterCard<Content: View>: View {
    let title: String
    var accent: Color?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let accent {
                    Circle()
                        .fill(accent)
                        .frame(width: 10, height: 10)
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(accent ?? .primary)
            }

            VStack(spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        EncounterView(pokemonId: 1)
    }
    .environmentObject(ListsController())
}
