import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSettings = false
    @State private var showingAddTab = false
    @State private var newTabTitle = ""
    @State private var newTabType: TabType = .command
    @State private var newTabPassword = ""
    
    @State private var showingTabPasswordPrompt = false
    @State private var tabPasswordInput = ""
    @State private var tabPasswordError = false
    @State private var pendingTabId: UUID?
    
    @State private var showingDeleteConfirm = false
    @State private var deleteTabId: UUID?
    @State private var deletePasswordInput = ""
    @State private var deletePasswordError = false
    
    // For renaming
    @State private var renamingTabId: UUID?
    @State private var renameTitle = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Text("Alias")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("v0.1")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.5))
                
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if showingSettings {
                SettingsContentView()
            } else {
                // Tab Bar Area
                HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(appState.tabs) { tab in
                            TabPill(tab: tab, 
                                    isActive: appState.selectedTabId == tab.id,
                                    renamingTabId: $renamingTabId,
                                    renameTitle: $renameTitle,
                                    onDeleteWithPassword: { show, tabId in
                                        if show {
                                            showingDeleteConfirm = true
                                            deleteTabId = tabId
                                        } else if let id = tabId {
                                            appState.deleteTab(id: id)
                                        }
                                    }) {
                                if let previousId = appState.selectedTabId, previousId != tab.id {
                                    let currentTab = appState.tabs.first { $0.id == previousId }
                                    let needsLock = currentTab?.tabPasswordHash != nil
                                    if needsLock {
                                        appState.lockTab(id: previousId)
                                        DispatchQueue.main.async {
                                            appState.selectedTabId = tab.id
                                        }
                                        return
                                    }
                                }
                                appState.selectedTabId = tab.id
                            } onRenameCommit: { id, newTitle in
                                appState.updateTab(id: id, newTitle: newTitle)
                                renamingTabId = nil
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                
                Button(action: {
                    showingAddTab = true
                }) {
                    Image(systemName: "plus")
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 10)
                .popover(isPresented: $showingAddTab, arrowEdge: .bottom) {
                    AddTabView { title, type, password in
                        appState.addTab(title: title, type: type)
                        if let lastTab = appState.tabs.last, let password = password {
                            appState.setTabPassword(id: lastTab.id, password: password)
                        }
                        showingAddTab = false
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content Area
            if let selectedTab = appState.tabs.first(where: { $0.id == appState.selectedTabId }) {
                let isLocked = selectedTab.tabPasswordHash != nil && !appState.isTabUnlocked(id: selectedTab.id)
                
                Group {
                    if isLocked {
                        LockedTabView(
                            tabName: selectedTab.title,
                            password: $tabPasswordInput,
                            error: tabPasswordError,
                            onUnlock: {
                                if appState.unlockTab(id: selectedTab.id, password: tabPasswordInput) {
                                    tabPasswordInput = ""
                                    tabPasswordError = false
                                } else {
                                    tabPasswordError = true
                                }
                            },
                            onCancel: {
                                appState.selectedTabId = appState.tabs.first?.id
                                tabPasswordInput = ""
                                tabPasswordError = false
                            }
                        )
                    } else {
                        if selectedTab.type == .command {
                            CommandTabView(tab: selectedTab)
                        } else if selectedTab.type == .note {
                            NoteTabView(tab: selectedTab)
                        } else if selectedTab.type == .password {
                            PasswordTabView(tab: selectedTab)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            } else {
                Text("No tab selected or tabs list is empty.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
            }
            }
        }
        .sheet(isPresented: $showingDeleteConfirm) {
            VStack(spacing: 20) {
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
                            let wasSelected = appState.selectedTabId == tabId
                            showingDeleteConfirm = false
                            deleteTabId = nil
                            deletePasswordInput = ""
                            deletePasswordError = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                appState.deleteTab(id: tabId)
                                if wasSelected {
                                    appState.selectedTabId = appState.tabs.first?.id
                                }
                            }
                        } else {
                            deletePasswordError = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(deletePasswordInput.isEmpty)
                }
            }
            .padding(40)
            .frame(width: 300)
        }
    }
}

// Custom Tab Pill View
struct TabPill: View {
    @EnvironmentObject var appState: AppState
    let tab: TabItem
    let isActive: Bool
    
    @Binding var renamingTabId: UUID?
    @Binding var renameTitle: String
    
    var onDeleteWithPassword: (Bool, UUID?) -> Void
    
    var onSelect: () -> Void
    var onRenameCommit: (UUID, String) -> Void
    
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
    
    var body: some View {
        Group {
            if renamingTabId == tab.id {
                TextField("Title", text: $renameTitle, onCommit: {
                    onRenameCommit(tab.id, renameTitle)
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 100)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: iconName)
                        .font(.system(size: 10))
                    Text(tab.title)
                        .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(isActive ? Color.accentColor : Color.clear)
                .foregroundColor(isActive ? .white : .primary)
                .cornerRadius(6)
                .onTapGesture {
                    onSelect()
                }
                .contextMenu {
                    Button("Rename") {
                        renameTitle = tab.title
                        renamingTabId = tab.id
                    }
                    Button("Delete", role: .destructive) {
                        onDeleteWithPassword(tab.tabPasswordHash != nil, tab.id)
                    }
                }
            }
        }
    }
}

// Add Tab Popover View
struct AddTabView: View {
    @State private var title: String = ""
    @State private var type: TabType = .command
    @State private var tabPassword: String = ""
    
    var onAdd: (String, TabType, String?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Tab")
                .font(.headline)
            
            TextField("Tab Name", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Picker("Type", selection: $type) {
                Text("Command").tag(TabType.command)
                Text("Note").tag(TabType.note)
                Text("Password").tag(TabType.password)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            SecureField("Tab Password (optional)", text: $tabPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Add") {
                if !title.isEmpty {
                    onAdd(title, type, tabPassword.isEmpty ? nil : tabPassword)
                }
            }
            .disabled(title.isEmpty)
            .keyboardShortcut(.defaultAction)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(width: 250)
    }
}

// Locked Tab View
struct LockedTabView: View {
    let tabName: String
    @Binding var password: String
    let error: Bool
    let onUnlock: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(tabName)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Enter password to unlock")
                .font(.caption)
                .foregroundColor(.secondary)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
            
            if error {
                Text("Incorrect password")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                
                Button("Unlock", action: onUnlock)
                    .buttonStyle(.borderedProminent)
                    .disabled(password.isEmpty)
            }
            
            Spacer()
        }
        .padding()
    }
}
