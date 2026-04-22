import SwiftUI
import AppKit

@main
struct MenuBarApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra("Alias", systemImage: "terminal") {
            ContentView()
                .environmentObject(appState)
                .frame(width: 400, height: 350)
            
            Divider()
            
            Menu {
                Button("About Alias") {
                    showAboutWindow()
                }
                
                Button("Settings...") {
                    showSettingsWindow()
                }
                
                Divider()
                
                Button("Quit Alias") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .menuBarExtraStyle(.window)
    }
    
    private func showSettingsWindow() {
        let settingsView = SettingsView()
            .environmentObject(appState)
        
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 350, height: 300))
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func showAboutWindow() {
        let aboutView = AboutView()
        let hostingController = NSHostingController(rootView: aboutView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "About Alias"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "terminal")
                .font(.system(size: 50))
                .foregroundColor(.accentColor)
            
            Text("Alias")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("A menu bar app for storing commands and notes.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Close") {
                NSApplication.shared.keyWindow?.close()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(30)
        .frame(width: 280)
    }
}