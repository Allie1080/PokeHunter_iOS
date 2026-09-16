import SwiftUI

@main
struct PokeHunterApp: App {
    @StateObject private var listsController = ListsController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(listsController)
        }
    }
}
