import SwiftUI

@main
struct CalmJournalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Sync with cloud on app launch
                    await StorageService.shared.syncWithCloud()
                }
        }
    }
}
