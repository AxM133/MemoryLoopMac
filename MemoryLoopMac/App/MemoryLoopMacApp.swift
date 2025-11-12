import SwiftUI
import UserNotifications

@main
struct MemoryLoopMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var store    = MemoryStore.shared
    @StateObject private var notif    = NotificationManager.shared
    @StateObject private var appState = AppState.shared
    @StateObject private var windows  = WindowService.shared

    var body: some Scene {
        MenuBarExtra("Memory Loop", systemImage: "brain.head.profile") {
            MenuContainer {
                ContentView()
                    .environmentObject(store)
                    .environmentObject(notif)
                    .environmentObject(appState)
                    .environmentObject(windows)
            }
            .environment(\.controlSize, .small)
            .accentColor(.blue)       
            .tint(.blue)
        }
        .menuBarExtraStyle(.window)
    }
}
