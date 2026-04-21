import SwiftUI

// MARK: - Command Tab View

struct CommandTabView: View {
    @EnvironmentObject var appState: AppState
    let tab: TabItem
    
    @State private var commandText: String = ""
    @State private var isEditing: Bool = false
    @State private var showCopiedIndicator = false
    
    var body: some View {
        VStack(spacing: 20) {
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Command:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $commandText)
                        .font(.system(.body, design: .monospaced))
                        .padding(4)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    
                    HStack {
                        Spacer()
                        Button("Cancel") {
                            commandText = tab.content
                            isEditing = false
                        }
                        Button("Save") {
                            appState.updateContent(id: tab.id, newContent: commandText)
                            isEditing = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            } else {
                Spacer()
                
                Text(tab.content.isEmpty ? "No command stored" : tab.content)
                    .font(.system(size: 16, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Button(action: {
                    copyToClipboard(tab.content)
                }) {
                    HStack {
                        Image(systemName: showCopiedIndicator ? "checkmark.circle.fill" : "doc.on.doc")
                        Text(showCopiedIndicator ? "Copied!" : "Copy Command")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(showCopiedIndicator ? Color.green : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(tab.content.isEmpty)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: {
                        isEditing = true
                    }) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .padding()
                }
            }
        }
        .onAppear {
            commandText = tab.content
        }
        .onChange(of: tab.id) { _ in
            // Reset state when tab changes
            commandText = tab.content
            isEditing = false
            showCopiedIndicator = false
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        withAnimation {
            showCopiedIndicator = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedIndicator = false
            }
        }
    }
}

// MARK: - Note Tab View

struct NoteTabView: View {
    @EnvironmentObject var appState: AppState
    let tab: TabItem
    
    @State private var noteText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $noteText)
                .font(.body)
                .padding()
                .onChange(of: noteText) { newValue in
                    // Autosave changes
                    appState.updateContent(id: tab.id, newContent: newValue)
                }
        }
        .onAppear {
            noteText = tab.content
        }
        .onChange(of: tab.id) { _ in
            noteText = tab.content
        }
    }
}
