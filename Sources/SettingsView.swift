import SwiftUI

struct SettingsContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddTab = false
    @State private var newTabTitle = ""
    @State private var newTabType: TabType = .command
    
    @State private var showingDeleteConfirm = false
    @State private var deleteTabId: UUID?
    @State private var deletePasswordInput = ""
    @State private var deletePasswordError = false
    @State private var isDeleteProtected = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tabs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                List {
                    ForEach(appState.tabs) { tab in
                        TabSettingsRow(
                            tab: tab,
                            showingDeleteConfirm: $showingDeleteConfirm,
                            deleteTabId: $deleteTabId,
                            isDeleteProtected: $isDeleteProtected
                        )
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
        .sheet(isPresented: $showingAddTab) {
            AddTabView { title, type, password in
                appState.addTab(title: title, type: type)
                if let lastTab = appState.tabs.last, let password = password {
                    appState.setTabPassword(id: lastTab.id, password: password)
                }
                newTabTitle = ""
                showingAddTab = false
            }
        }
        .sheet(isPresented: $showingDeleteConfirm) {
            VStack(spacing: 20) {
                if isDeleteProtected {
                    Text("Delete Protected Tab")
                        .font(.headline)
                    
                    Text("Enter password to delete this tab")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    SecureField("Password", text: $deletePasswordInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                    
                    if deletePasswordError {
                        Text("Incorrect password")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Button("Cancel") {
                            showingDeleteConfirm = false
                            deleteTabId = nil
                            deletePasswordInput = ""
                            deletePasswordError = false
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        
                        Button("Delete") {
                            if let tabId = deleteTabId,
                               appState.unlockTab(id: tabId, password: deletePasswordInput) {
                                showingDeleteConfirm = false
                                deleteTabId = nil
                                deletePasswordInput = ""
                                deletePasswordError = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    appState.deleteTab(id: tabId)
                                }
                            } else {
                                deletePasswordError = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(deletePasswordInput.isEmpty)
                    }
                } else {
                    if let tabToDelete = appState.tabs.first(where: { $0.id == deleteTabId }) {
                        Text("Delete \"\(tabToDelete.title)\"?")
                            .font(.headline)
                        
                        Text("This action cannot be undone.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button("Cancel") {
                                showingDeleteConfirm = false
                                deleteTabId = nil
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            
                            Button("Delete") {
                                if let tabId = deleteTabId {
                                    showingDeleteConfirm = false
                                    deleteTabId = nil
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        appState.deleteTab(id: tabId)
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .padding(40)
            .frame(width: 300)
        }
    }
    
    private func moveTabs(from source: IndexSet, to destination: Int) {
        appState.moveTab(from: source, to: destination)
    }
}

struct TabSettingsRow: View {
    @EnvironmentObject var appState: AppState
    let tab: TabItem
    
    @Binding var showingDeleteConfirm: Bool
    @Binding var deleteTabId: UUID?
    @Binding var isDeleteProtected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(tab.title)
            
            Spacer()
            
            Button(action: {
                isDeleteProtected = tab.tabPasswordHash != nil
                showingDeleteConfirm = true
                deleteTabId = tab.id
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

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showingAddTab = false
    @State private var newTabTitle = ""
    @State private var newTabType: TabType = .command
    
    @State private var showingDeleteConfirm = false
    @State private var deleteTabId: UUID?
    @State private var deletePasswordInput = ""
    @State private var deletePasswordError = false
    @State private var isDeleteProtected = false
    
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
                        TabSettingsRow(
                            tab: tab,
                            showingDeleteConfirm: $showingDeleteConfirm,
                            deleteTabId: $deleteTabId,
                            isDeleteProtected: $isDeleteProtected
                        )
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
            AddTabView { title, type, password in
                appState.addTab(title: title, type: type)
                if let lastTab = appState.tabs.last, let password = password {
                    appState.setTabPassword(id: lastTab.id, password: password)
                }
                newTabTitle = ""
                showingAddTab = false
            }
        }
        .sheet(isPresented: $showingDeleteConfirm) {
            VStack(spacing: 20) {
                if isDeleteProtected {
                    Text("Delete Protected Tab")
                        .font(.headline)
                    
                    Text("Enter password to delete this tab")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    SecureField("Password", text: $deletePasswordInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                    
                    if deletePasswordError {
                        Text("Incorrect password")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Button("Cancel") {
                            showingDeleteConfirm = false
                            deleteTabId = nil
                            deletePasswordInput = ""
                            deletePasswordError = false
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        
                        Button("Delete") {
                            if let tabId = deleteTabId,
                               appState.unlockTab(id: tabId, password: deletePasswordInput) {
                                showingDeleteConfirm = false
                                deleteTabId = nil
                                deletePasswordInput = ""
                                deletePasswordError = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    appState.deleteTab(id: tabId)
                                }
                            } else {
                                deletePasswordError = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(deletePasswordInput.isEmpty)
                    }
                } else {
                    if let tabToDelete = appState.tabs.first(where: { $0.id == deleteTabId }) {
                        Text("Delete \"\(tabToDelete.title)\"?")
                            .font(.headline)
                        
                        Text("This action cannot be undone.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button("Cancel") {
                                showingDeleteConfirm = false
                                deleteTabId = nil
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            
                            Button("Delete") {
                                if let tabId = deleteTabId {
                                    showingDeleteConfirm = false
                                    deleteTabId = nil
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        appState.deleteTab(id: tabId)
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .padding(40)
            .frame(width: 300)
        }
    }
    
    private func moveTabs(from source: IndexSet, to destination: Int) {
        appState.moveTab(from: source, to: destination)
    }
}