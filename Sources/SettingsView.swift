import SwiftUI

struct SettingsContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddTab = false
    @State private var newTabTitle = ""
    @State private var newTabType: TabType = .command
    
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
                        // Top indicator
                        dropIndicator(at: 0)
                        
                        ForEach(Array(appState.tabs.enumerated()), id: \.element.id) { index, tab in
                            TabSettingsRow(tab: tab)
                                .opacity(draggingTabId == tab.id ? 0.5 : 1.0)
                                .offset(draggingTabId == tab.id ? dragOffset : .zero)
                                .scaleEffect(draggingTabId == tab.id ? 1.02 : 1.0)
                                .animation(Animation.default, value: draggingTabId)
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
                            
                            // Bottom indicator for each row
                            dropIndicator(at: index + 1)
                        }
                    }
                }
            }
            
            Divider()
            
            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit Alias")
                }
                .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    @ViewBuilder
    private func dropIndicator(at lineIndex: Int) -> some View {
        if let targetIdx = dropTargetIndex,
           let dragId = draggingTabId,
           let sourceIndex = appState.tabs.firstIndex(where: { $0.id == dragId }) {
            
            // Map the expected final array index to the correct visual line gap
            let visualTargetLine = targetIdx > sourceIndex ? targetIdx + 1 : targetIdx
            
            // Only show if the line matches and it wouldn't drop exactly where it started
            if visualTargetLine == lineIndex && targetIdx != sourceIndex {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.5))
                    .frame(height: 2)
                    .padding(.horizontal, 8)
            }
        }
    }
    
    private func updateDropTargetIndex(currentIndex: Int, translation: CGSize) {
        let itemHeight: CGFloat = 36 // row height
        
        // Calculate the raw array index offset
        let offset = Int(round(translation.height / itemHeight))
        var newIndex = currentIndex + offset
        
        // Target is directly representing the exact array index it will end up at.
        // It should be safely clamped to prevent inserting out of bounds.
        let maxIndex = max(0, appState.tabs.count - 1)
        newIndex = max(0, min(newIndex, maxIndex))
        
        if newIndex != dropTargetIndex {
            dropTargetIndex = newIndex
        }
    }
    
    private func handleDrop(tabId: UUID, at targetIndex: Int) {
        guard let currentIndex = appState.tabs.firstIndex(where: { $0.id == tabId }) else { return }
        
        // Prevent no-op triggers
        if targetIndex != currentIndex {
            appState.moveTab(from: IndexSet(integer: currentIndex), to: targetIndex)
        }
    }
}

struct TabSettingsRow: View {
    @EnvironmentObject var appState: AppState
    let tab: TabItem
    
    @State private var showingDeletePopover = false
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(tab.title)
            
            Spacer()
            
            Button(action: {
                showingDeletePopover = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingDeletePopover, arrowEdge: .bottom) {
                DeleteTabView(tab: tab) {
                    appState.deleteTab(id: tab.id)
                    showingDeletePopover = false
                } onCancel: {
                    showingDeletePopover = false
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
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
                        // Top indicator
                        dropIndicator(at: 0)
                        
                        ForEach(Array(appState.tabs.enumerated()), id: \.element.id) { index, tab in
                            TabSettingsRow(tab: tab)
                                .opacity(draggingTabId == tab.id ? 0.5 : 1.0)
                                .offset(draggingTabId == tab.id ? dragOffset : .zero)
                                .scaleEffect(draggingTabId == tab.id ? 1.02 : 1.0)
                                .animation(Animation.default, value: draggingTabId)
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
                            
                            // Bottom indicator for each row
                            dropIndicator(at: index + 1)
                        }
                    }
                }
            }
            
            Divider()
            
            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit Alias")
                }
                .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(width: 350, height: 320)
    }
    
    @ViewBuilder
    private func dropIndicator(at lineIndex: Int) -> some View {
        if let targetIdx = dropTargetIndex,
           let dragId = draggingTabId,
           let sourceIndex = appState.tabs.firstIndex(where: { $0.id == dragId }) {
            
            // Map the expected final array index to the correct visual line gap
            let visualTargetLine = targetIdx > sourceIndex ? targetIdx + 1 : targetIdx
            
            if visualTargetLine == lineIndex && targetIdx != sourceIndex {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.5))
                    .frame(height: 2)
                    .padding(.horizontal, 8)
            }
        }
    }
    
    private func updateDropTargetIndex(currentIndex: Int, translation: CGSize) {
        let itemHeight: CGFloat = 36 // row height
        
        // Calculate the raw array index offset
        let offset = Int(round(translation.height / itemHeight))
        var newIndex = currentIndex + offset
        
        // Target is directly representing the exact array index it will end up at.
        let maxIndex = max(0, appState.tabs.count - 1)
        newIndex = max(0, min(newIndex, maxIndex))
        
        if newIndex != dropTargetIndex {
            dropTargetIndex = newIndex
        }
    }
    
    private func handleDrop(tabId: UUID, at targetIndex: Int) {
        guard let currentIndex = appState.tabs.firstIndex(where: { $0.id == tabId }) else { return }
        
        // Prevent no-op triggers
        if targetIndex != currentIndex {
            appState.moveTab(from: IndexSet(integer: currentIndex), to: targetIndex)
        }
    }
}