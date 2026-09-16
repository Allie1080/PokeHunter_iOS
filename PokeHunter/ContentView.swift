import SwiftUI

enum Route: Hashable {
    case detail(pokemonId: Int)
    case encounter(pokemonId: Int)
    case listDetail(listId: UUID)
    case caughtList(kind: CaughtListKind)
}

enum CaughtListKind: String, Identifiable, Hashable, CaseIterable {
    case regular = "Regular"
    case shiny = "Shiny"

    var id: String { rawValue }

    var systemImage: String {
        self == .shiny ? "sparkles" : "checkmark.circle.fill"
    }
}

struct ContentView: View {

    var body: some View {
        TabView {
            NavigationStack {
                GalleryView()
                    .withPokeHunterDestinations()
            }
            .tabItem {
                Label("Gallery", systemImage: "square.grid.3x3.fill")
            }

            NavigationStack {
                ListsView()
                    .withPokeHunterDestinations()
            }
            .tabItem {
                Label("Lists", systemImage: "list.bullet.rectangle")
            }

            NavigationStack {
                SearchGuideView()
            }
            .tabItem {
                Label("Search Guide", systemImage: "questionmark.circle")
            }
        }
    }
}

extension View {
    func withPokeHunterDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .detail(let pokemonId):
                DetailView(pokemonId: pokemonId)
                    .toolbar(.hidden, for: .tabBar)

            case .encounter(let pokemonId):
                EncounterView(pokemonId: pokemonId)
                    .toolbar(.hidden, for: .tabBar)

            case .listDetail(let listId):
                ListDetailView(listId: listId)

            case .caughtList(let kind):
                CaughtListView(kind: kind)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ListsController())
}
