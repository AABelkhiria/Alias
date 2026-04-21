import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddTab = false
    @State private var newTabTitle = ""
    @State private var newTabType: TabType = .command
    
    // For renaming
    @State private var renamingTabId: UUID?
    @State private var renameTitle = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar Area
            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(appState.tabs) { tab in
                            TabPill(tab: tab, 
                                    isActive: appState.selectedTabId == tab.id,
                                    renamingTabId: $renamingTabId,
                                    renameTitle: $renameTitle) {
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
                    AddTabView { title, type in
                        appState.addTab(title: title, type: type)
                        showingAddTab = false
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content Area
            if let selectedTab = appState.tabs.first(where: { $0.id == appState.selectedTabId }) {
                Group {
                    if selectedTab.type == .command {
                        CommandTabView(tab: selectedTab)
                    } else if selectedTab.type == .note {
                        NoteTabView(tab: selectedTab)
                    } else if selectedTab.type == .password {
                        PasswordTabView(tab: selectedTab)
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

// Custom Tab Pill View
struct TabPill: View {
    @EnvironmentObject var appState: AppState
    let tab: TabItem
    let isActive: Bool
    
    @Binding var renamingTabId: UUID?
    @Binding var renameTitle: String
    
    var onSelect: () -> Void
    var onRenameCommit: (UUID, String) -> Void
    
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
                    Image(systemName: tab.type == .command ? "terminal" : (tab.type == .password ? "lock.fill" : "note.text"))
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
                        appState.deleteTab(id: tab.id)
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
    
    var onAdd: (String, TabType) -> Void
    
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
            
            Button("Add") {
                if !title.isEmpty {
                    onAdd(title, type)
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
