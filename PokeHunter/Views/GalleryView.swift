import SwiftUI

struct GalleryView: View {

    @StateObject private var controller = GalleryController()
    @EnvironmentObject private var lists: ListsController

    @State private var isShowingTypeSheet = false
    @State private var isShowingGenerationSheet = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: []) {
                FiltersCard(
                    controller: controller,
                    onOpenGenerations: { isShowingGenerationSheet = true },
                    onOpenTypes: { isShowingTypeSheet = true }
                )

                if let searchError = controller.searchError {
                    Label(searchError, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .navigationTitle("PokeHunter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .searchable(
            text: $controller.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Constants.Copy.searchPlaceholder
        )
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .onSubmit(of: .search) {
            Task { await controller.runSearch() }
        }
        .onChange(of: controller.searchText) { _, newValue in
            if newValue.isEmpty { Task { await controller.clearSearch() } }
        }
        .task { await controller.loadIfNeeded() }
        .sheet(isPresented: $isShowingTypeSheet) {
            TypeFilterModal(selected: controller.selectedTypes) { types in
                Task { await controller.applyTypeSelection(types) }
            }
        }
        .sheet(isPresented: $isShowingGenerationSheet) {
            GenerationFilterModal(selected: controller.selectedGenerations) { generations in
                Task {
                    controller.selectedGenerations = generations
                    await controller.applyFilters()
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if controller.isLoading && controller.visiblePokemon.isEmpty {
            ProgressView("Loading Pokédex…")
                .padding(.vertical, 60)

        } else if let errorMessage = controller.errorMessage {
            EmptyStateView(
                systemImage: "wifi.exclamationmark",
                title: "Couldn't load the Pokédex",
                message: errorMessage,
                actionTitle: "Try again",
                action: { Task { await controller.load() } }
            )

        } else if controller.visiblePokemon.isEmpty {
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "No Pokémon match those filters",
                message: "Try removing a type, or widening the generation range.",
                actionTitle: controller.hasActiveFilters ? "Reset filters" : nil,
                action: controller.hasActiveFilters
                    ? { Task { await controller.resetAllFilters() } }
                    : nil
            )

        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(controller.visiblePokemon) { pokemon in
                    NavigationLink(value: Route.detail(pokemonId: pokemon.id)) {
                        PokemonCard(pokemon: pokemon)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct FiltersCard: View {

    @ObservedObject var controller: GalleryController
    let onOpenGenerations: () -> Void
    let onOpenTypes: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Filters")
                    .font(.headline)
                Spacer()
                if controller.hasActiveFilters {
                    Button("Reset") {
                        Task { await controller.resetAllFilters() }
                    }
                    .font(.footnote)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            VStack(spacing: 0) {
                Divider()

                DisclosureRow(
                    title: "Generation",
                    value: controller.generationLabel,
                    action: onOpenGenerations
                )

                Divider().padding(.leading, 16)

                ToggleRow(
                    title: "Legendary",
                    isOn: Binding(
                        get: { controller.showLegendaryOnly },
                        set: { newValue in
                            controller.showLegendaryOnly = newValue
                            Task { await controller.applyFilters() }
                        }
                    )
                )

                Divider().padding(.leading, 16)

                ToggleRow(
                    title: "Mythical",
                    isOn: Binding(
                        get: { controller.showMythicalOnly },
                        set: { newValue in
                            controller.showMythicalOnly = newValue
                            Task { await controller.applyFilters() }
                        }
                    )
                )

                Divider().padding(.leading, 16)

                DisclosureRow(
                    title: "Types",
                    value: controller.typeFilterCount == 0 ? "0" : "\(controller.typeFilterCount)",
                    action: onOpenTypes
                )
            }
        }
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct DisclosureRow: View {
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .tint(Color.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}

private struct TypeFilterModal: View {

    @State private var selection: Set<String>
    let onApply: (Set<String>) -> Void

    @Environment(\.dismiss) private var dismiss

    init(selected: Set<String>, onApply: @escaping (Set<String>) -> Void) {
        _selection = State(initialValue: selected)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Types") {
                    ForEach(Constants.PokemonTypes.all, id: \.self) { type in
                        Button {
                            if selection.contains(type) {
                                selection.remove(type)
                            } else {
                                selection.insert(type)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Constants.PokemonTypes.color(for: type))
                                    .frame(width: 10, height: 10)

                                Text(type.capitalizedWords)
                                    .foregroundStyle(Color.primary)

                                Spacer()

                                if selection.contains(type) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Type Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") { selection.removeAll() }
                        .disabled(selection.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply", systemImage: "checkmark") {
                        onApply(selection)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct GenerationFilterModal: View {

    @State private var selection: Set<Int>
    let onApply: (Set<Int>) -> Void

    @Environment(\.dismiss) private var dismiss

    init(selected: Set<Int>, onApply: @escaping (Set<Int>) -> Void) {
        _selection = State(initialValue: selected)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selection.removeAll()
                    } label: {
                        HStack {
                            Text("All Generations")
                                .foregroundStyle(Color.primary)
                            Spacer()
                            if selection.isEmpty {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Section("Generations") {
                    ForEach(Array(Constants.Generations.supported), id: \.self) { generation in
                        Button {
                            if selection.contains(generation) {
                                selection.remove(generation)
                            } else {
                                selection.insert(generation)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Generation \(generation)")
                                        .foregroundStyle(Color.primary)
                                    Text(Constants.Generations.regions[generation] ?? "")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                                Spacer()
                                if selection.contains(generation) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Generation Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply", systemImage: "checkmark") {
                        onApply(selection)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GalleryView()
            .withPokeHunterDestinations()
    }
    .environmentObject(ListsController())
}
