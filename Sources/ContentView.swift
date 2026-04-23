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
    
    @State private var showingDeletePopover = false
    @State private var pendingDeleteTab: TabItem?
    
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
                                    showingDeletePopover: $showingDeletePopover,
                                    pendingDeleteTab: $pendingDeleteTab) {
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
    }
}

// Custom Tab Pill View
struct TabPill: View {
    @EnvironmentObject var appState: AppState
    let tab: TabItem
    let isActive: Bool
    
    @Binding var renamingTabId: UUID?
    @Binding var renameTitle: String
    @Binding var showingDeletePopover: Bool
    @Binding var pendingDeleteTab: TabItem?
    
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
                        pendingDeleteTab = tab
                        showingDeletePopover = true
                    }
                }
                .popover(isPresented: $showingDeletePopover, arrowEdge: .bottom) {
                    if let tabToDelete = pendingDeleteTab {
                        DeleteTabView(tab: tabToDelete) {
                            let wasSelected = appState.selectedTabId == tabToDelete.id
                            appState.deleteTab(id: tabToDelete.id)
                            if wasSelected {
                                appState.selectedTabId = appState.tabs.first?.id
                            }
                            showingDeletePopover = false
                            pendingDeleteTab = nil
                        } onCancel: {
                            showingDeletePopover = false
                            pendingDeleteTab = nil
                        }
                    }
                }
            }
        }
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
        }
        .padding()
    }
}
