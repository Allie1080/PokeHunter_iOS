import SwiftUI

struct ListsView: View {

    @EnvironmentObject private var lists: ListsController

    @State private var isCreatingList = false

    var body: some View {
        List {
            Section("Caught") {
                caughtRow(.regular, count: lists.regularCaught.count)
                caughtRow(.shiny, count: lists.shinyCaught.count)
            }

            Section("Custom") {
                if lists.customLists.isEmpty {
                    Text("No lists yet. Tap + to make one.")
                        .foregroundStyle(.secondary)
                }

                ForEach(lists.customLists) { list in
                    NavigationLink(value: Route.listDetail(listId: list.id)) {
                        row(title: list.name, subtitle: "\(lists.count(for: list)) Pokémon")
                    }
                }
                .onDelete { offsets in
                    lists.delete(atOffsets: offsets)
                }
            }
        }
        .navigationTitle("My Lists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isCreatingList = true
                } label: {
                    Label("New List", systemImage: "plus")
                }
            }
        }
        .onAppear { lists.refresh() }
        .sheet(isPresented: $isCreatingList) {
            CreateListModal()
                .environmentObject(lists)
        }
    }

    private func caughtRow(_ kind: CaughtListKind, count: Int) -> some View {
        NavigationLink(value: Route.caughtList(kind: kind)) {
            row(title: kind.rawValue, subtitle: "\(count) Pokémon")
        }
    }

    private func row(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundStyle(Color.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        ListsView()
            .withPokeHunterDestinations()
    }
    .environmentObject(ListsController())
}
