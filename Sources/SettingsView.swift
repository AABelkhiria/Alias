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
    
    @State private var draggingTabId: UUID?
    @State private var dragOffset: CGSize = .zero
    @State private var dropTargetIndex: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tabs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { showingAddTab = true }) {
                        Image(systemName: "plus")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .popover(isPresented: $showingAddTab, arrowEdge: .bottom) {
                        AddTabView { title, type, password in
                            appState.addTab(title: title, type: type)
                            if let lastTab = appState.tabs.last, let password = password {
                                appState.setTabPassword(id: lastTab.id, password: password)
                            }
                            newTabTitle = ""
                            showingAddTab = false
                        }
                    }
                }
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(appState.tabs.enumerated()), id: \.element.id) { index, tab in
                            TabSettingsRow(
                                tab: tab,
                                showingDeleteConfirm: $showingDeleteConfirm,
                                deleteTabId: $deleteTabId,
                                isDeleteProtected: $isDeleteProtected
                            )
                            .opacity(draggingTabId == tab.id ? 0.5 : 1.0)
                            .offset(draggingTabId == tab.id ? dragOffset : .zero)
                            .scaleEffect(draggingTabId == tab.id ? 1.02 : 1.0)
                            .animation(.default, value: draggingTabId)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if draggingTabId == nil {
                                            draggingTabId = tab.id
                                        }
                                        dragOffset = value.translation
                                        updateDropTargetIndex(currentIndex: index, translation: value.translation)
                                    }
                                    .onEnded { _ in
                                        if let targetIndex = dropTargetIndex, let dragId = draggingTabId {
                                            handleDrop(tabId: dragId, at: targetIndex)
                                        }
                                        draggingTabId = nil
                                        dragOffset = .zero
                                        dropTargetIndex = nil
                                    }
                            )
                            
                            if let targetIdx = dropTargetIndex, targetIdx == index + 1 {
                                Rectangle()
                                    .fill(Color.accentColor.opacity(0.5))
                                    .frame(height: 2)
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
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
    
    private func updateDropTargetIndex(currentIndex: Int, translation: CGSize) {
        // Simple logic: move target index based on drag direction
        let itemHeight: CGFloat = 44 // approximate row height
        let offset = Int(translation.height / itemHeight)
        
        var newIndex = currentIndex + offset
        newIndex = max(0, min(newIndex, appState.tabs.count - 1))
        
        if newIndex != dropTargetIndex {
            dropTargetIndex = newIndex
        }
    }
    
    private func handleDrop(tabId: UUID, at targetIndex: Int) {
        guard let currentIndex = appState.tabs.firstIndex(where: { $0.id == tabId }) else { return }
        
        var newTarget = targetIndex
        if newTarget > currentIndex {
            newTarget -= 1
        }
        
        if newTarget != currentIndex {
            appState.moveTab(from: IndexSet(integer: currentIndex), to: newTarget)
        }
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
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
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
    
    @State private var draggingTabId: UUID?
    @State private var dragOffset: CGSize = .zero
    @State private var dropTargetIndex: Int?
    
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
                HStack {
                    Text("Tabs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { showingAddTab = true }) {
                        Image(systemName: "plus")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .popover(isPresented: $showingAddTab, arrowEdge: .bottom) {
                        AddTabView { title, type, password in
                            appState.addTab(title: title, type: type)
                            if let lastTab = appState.tabs.last, let password = password {
                                appState.setTabPassword(id: lastTab.id, password: password)
                            }
                            newTabTitle = ""
                            showingAddTab = false
                        }
                    }
                }
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(appState.tabs.enumerated()), id: \.element.id) { index, tab in
                            TabSettingsRow(
                                tab: tab,
                                showingDeleteConfirm: $showingDeleteConfirm,
                                deleteTabId: $deleteTabId,
                                isDeleteProtected: $isDeleteProtected
                            )
                            .opacity(draggingTabId == tab.id ? 0.5 : 1.0)
                            .offset(draggingTabId == tab.id ? dragOffset : .zero)
                            .scaleEffect(draggingTabId == tab.id ? 1.02 : 1.0)
                            .animation(.default, value: draggingTabId)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if draggingTabId == nil {
                                            draggingTabId = tab.id
                                        }
                                        dragOffset = value.translation
                                        updateDropTargetIndex(currentIndex: index, translation: value.translation)
                                    }
                                    .onEnded { _ in
                                        if let targetIndex = dropTargetIndex, let dragId = draggingTabId {
                                            handleDrop(tabId: dragId, at: targetIndex)
                                        }
                                        draggingTabId = nil
                                        dragOffset = .zero
                                        dropTargetIndex = nil
                                    }
                            )
                            
                            if let targetIdx = dropTargetIndex, targetIdx == index + 1 {
                                Rectangle()
                                    .fill(Color.accentColor.opacity(0.5))
                                    .frame(height: 2)
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(width: 350, height: 300)
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
    
    private func updateDropTargetIndex(currentIndex: Int, translation: CGSize) {
        let itemHeight: CGFloat = 44
        let offset = Int(translation.height / itemHeight)
        
        var newIndex = currentIndex + offset
        newIndex = max(0, min(newIndex, appState.tabs.count - 1))
        
        if newIndex != dropTargetIndex {
            dropTargetIndex = newIndex
        }
    }
    
    private func handleDrop(tabId: UUID, at targetIndex: Int) {
        guard let currentIndex = appState.tabs.firstIndex(where: { $0.id == tabId }) else { return }
        
        var newTarget = targetIndex
        if newTarget > currentIndex {
            newTarget -= 1
        }
        
        if newTarget != currentIndex {
            appState.moveTab(from: IndexSet(integer: currentIndex), to: newTarget)
        }
    }
}