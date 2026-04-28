import SwiftUI

struct SettingsContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddTab = false
    @State private var newTabTitle = ""
    @State private var newTabType: TabType = .command
    
    @State private var draggingTabId: UUID?
    @State private var dragOffset: CGSize = .zero
    @State private var dropTargetIndex: Int?
    @State private var showingInfoPopover = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Tabs Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 4) {
                        Text("Tabs")
                        Button(action: { showingInfoPopover = true }) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showingInfoPopover, arrowEdge: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Shortcuts")
                                    .font(.headline)
                                Text("⌘ 1-9 : Switch Tab")
                                Text("⌘ 0   : Toggle Settings")
                                Text("⌘ ⌫   : Delete Tab")
                                Text("⌘ N   : New Tab")
                                
                                Divider()
                                
                                Text("Drag and drop tabs in the list below to reorder them.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(width: 200)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { showingAddTab = true }) {
                        Image(systemName: "plus")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .keyboardShortcut("n", modifiers: .command)
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
            
            // Window Size Section
            WindowSizeSettingsView()
            
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
        .background(.ultraThinMaterial)
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

struct WindowSizeSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingEditPopover = false
    @State private var showingInfoPopover = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Text("Window Size")
                    Button(action: { showingInfoPopover = true }) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingInfoPopover, arrowEdge: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Shortcuts")
                                .font(.headline)
                            Text("⌘ + : Increase size (+50)")
                            Text("⌘ - : Decrease size (-50)")
                        }
                        .padding()
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { appState.resetWindowSize() }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Reset to default size")
                    
                    Button(action: { showingEditPopover = true }) {
                        Image(systemName: "pencil")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingEditPopover, arrowEdge: .bottom) {
                        EditWindowSizeView(
                            width: appState.windowWidth,
                            height: appState.windowHeight
                        ) { newW, newH in
                            appState.updateWindowSize(width: newW, height: newH)
                            showingEditPopover = false
                        } onCancel: {
                            showingEditPopover = false
                        }
                    }
                }
            }
            
            HStack(spacing: 20) {
                Label {
                    Text("\(Int(appState.windowWidth))")
                } icon: {
                    Text("W:").fontWeight(.semibold).foregroundColor(.secondary)
                }
                
                Label {
                    Text("\(Int(appState.windowHeight))")
                } icon: {
                    Text("H:").fontWeight(.semibold).foregroundColor(.secondary)
                }
            }
            .font(.system(.body, design: .monospaced))
        }
    }
}

struct EditWindowSizeView: View {
    @State private var width: Double
    @State private var height: Double
    
    var onSave: (CGFloat, CGFloat) -> Void
    var onCancel: () -> Void
    
    init(width: CGFloat, height: CGFloat, onSave: @escaping (CGFloat, CGFloat) -> Void, onCancel: @escaping () -> Void) {
        _width = State(initialValue: Double(width))
        _height = State(initialValue: Double(height))
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Window Size")
                .font(.headline)
            
            VStack(spacing: 10) {
                HStack {
                    Text("Width:")
                    Spacer()
                    TextField("", value: $width, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                }
                
                HStack {
                    Text("Height:")
                    Spacer()
                    TextField("", value: $height, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                }
            }
            
            Text("Min: \(Int(AppState.minWidth))x\(Int(AppState.minHeight)) / Max: \(Int(AppState.maxWidth))x\(Int(AppState.maxHeight))")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Save") {
                    onSave(CGFloat(width), CGFloat(height))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 220)
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
    @State private var showingInfoPopover = false
    
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Tabs Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 4) {
                                Text("Tabs")
                                Button(action: { showingInfoPopover = true }) {
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                .popover(isPresented: $showingInfoPopover, arrowEdge: .top) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Shortcuts")
                                            .font(.headline)
                                        Text("⌘ N : New Tab")
                                        
                                        Divider()
                                        
                                        Text("Drag and drop tabs in the list below to reorder them.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding()
                                    .frame(width: 200)
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: { showingAddTab = true }) {
                                Image(systemName: "plus")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .keyboardShortcut("n", modifiers: .command)
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
                    
                    Divider()
                    
                    // Window Size Section
                    WindowSizeSettingsView()
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
        .background(.ultraThinMaterial)
        .frame(width: 350, height: 400)
        .opacity(0.98)
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
