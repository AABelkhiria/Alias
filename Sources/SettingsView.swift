import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showingAddTab = false
    @State private var newTabTitle = ""
    @State private var newTabType: TabType = .command
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Settings")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Tabs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                List {
                    ForEach(appState.tabs) { tab in
                        TabSettingsRow(tab: tab)
                    }
                    .onMove(perform: moveTabs)
                    
                    Button(action: { showingAddTab = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add New Tab")
                        }
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .padding()
        .frame(width: 350, height: 300)
        .sheet(isPresented: $showingAddTab) {
            VStack(spacing: 12) {
                Text("Add New Tab")
                    .font(.headline)
                
                TextField("Tab Name", text: $newTabTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("Type", selection: $newTabType) {
                    Text("Command").tag(TabType.command)
                    Text("Note").tag(TabType.note)
                    Text("Password").tag(TabType.password)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                HStack {
                    Button("Cancel") {
                        newTabTitle = ""
                        showingAddTab = false
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button("Add") {
                        if !newTabTitle.isEmpty {
                            appState.addTab(title: newTabTitle, type: newTabType)
                            newTabTitle = ""
                            showingAddTab = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newTabTitle.isEmpty)
                }
            }
            .padding()
            .frame(width: 250)
        }
    }
    
    private func moveTabs(from source: IndexSet, to destination: Int) {
        appState.moveTab(from: source, to: destination)
    }
}

struct TabSettingsRow: View {
    @EnvironmentObject var appState: AppState
    let tab: TabItem
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(tab.title)
            
            Spacer()
            
            Button(action: {
                appState.deleteTab(id: tab.id)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var iconName: String {
        if tab.tabPasswordHash != nil {
            return "lock.fill"
        }
        if tab.type == .command {
            return "terminal"
        } else if tab.type == .password {
            return "key.fill"
        }
        return "note.text"
    }
}