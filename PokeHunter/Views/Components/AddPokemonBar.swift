import SwiftUI

struct AddPokemonBar: View {

    let onAdd: (PokemonDetail) -> Void

    @State private var searchText = ""
    @State private var isAdding = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Name or ID", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { Task { await add() } }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            errorMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground), in: Capsule())

                Button {
                    Task { await add() }
                } label: {
                    if isAdding {
                        ProgressView().frame(width: 40)
                    } else {
                        Label("Add", systemImage: "plus")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isDisabled)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var isDisabled: Bool {
        searchText.trimmingCharacters(in: .whitespaces).isEmpty || isAdding
    }

    private func add() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isAdding = true
        errorMessage = nil
        defer { isAdding = false }

        do {
            let detail = try await PokemonAPIWrapper.shared.fetchDetail(nameOrId: query)

            guard Constants.Generations.generation(for: detail.id) != nil else {
                errorMessage = "\(detail.displayName) is from a generation PokeHunter doesn't cover yet."
                return
            }

            onAdd(detail)
            searchText = ""
        } catch {
            errorMessage = "Couldn't find \u{201C}\(query)\u{201D}. "
                + "Try a name like \u{201C}milotic\u{201D} or a number like 350."
        }
    }
}

#Preview {
    AddPokemonBar { detail in print(detail.displayName) }
        .padding()
}
