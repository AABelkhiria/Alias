import SwiftUI

@main
struct MenuBarApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra("Alias", systemImage: "terminal") {
            ContentView()
                .environmentObject(appState)
                .frame(width: 400, height: 350)
            
            Divider()
            
            Button("Quit Alias") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
