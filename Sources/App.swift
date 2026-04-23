import SwiftUI
import AppKit

@main
struct MenuBarApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra("Alias", systemImage: "terminal") {
            ContentView()
                .environmentObject(appState)
                .frame(width: appState.windowWidth, height: appState.windowHeight)
        }
        .menuBarExtraStyle(.window)
    }
}