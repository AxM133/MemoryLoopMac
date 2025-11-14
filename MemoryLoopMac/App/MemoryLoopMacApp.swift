import SwiftUI

@main
struct MemoryLoopMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var store    = MemoryStore.shared
    @StateObject private var appState = AppState.shared
    @StateObject private var windows  = WindowService.shared

    var body: some Scene {
        MenuBarExtra("MemoryLoop", systemImage: "brain.head.profile") {
            MenuContainer {
                ContentView()
                    .environmentObject(store)
                    .environmentObject(appState)
                    .environmentObject(windows)
            }
            .tint(.blue)
        }
        .menuBarExtraStyle(.window)
    }
}
