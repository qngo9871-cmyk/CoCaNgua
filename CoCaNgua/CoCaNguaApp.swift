import SwiftUI

@main
struct CoCaNguaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(LocalizationManager.shared)
        }
    }
}
