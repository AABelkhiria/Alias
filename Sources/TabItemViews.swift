import SwiftUI

struct CommandTabView: View {
    @EnvironmentObject var appState: AppState
    let tab: TabItem
    
    @State private var editingCommandId: UUID?
    @State private var editTitle: String = ""
    @State private var editCommand: String = ""
    @State private var showCopiedId: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(tab.commands) { command in
                        CommandRowView(
                            command: command,
                            isEditing: editingCommandId == command.id,
                            isCopied: showCopiedId == command.id,
                            onCopy: { copyCommand(command.command, id: command.id) },
                            onEdit: {
                                editTitle = command.title
                                editCommand = command.command
                                editingCommandId = command.id
                            },
                            onSave: {
                                appState.updateCommand(tabId: tab.id, commandId: command.id, title: editTitle, command: editCommand)
                                editingCommandId = nil
                            },
                            onCancel: {
                                editingCommandId = nil
                            },
                            onDelete: {
                                appState.deleteCommand(from: tab.id, commandId: command.id)
                            }
                        )
                    }
                }
                .padding()
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button(action: {
                    appState.addCommand(to: tab.id)
                }) {
                    Image(systemName: "plus")
                    Text("Add Command")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .padding()
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onChange(of: tab.id) { _ in
            editingCommandId = nil
            showCopiedId = nil
        }
    }
    
    private func copyCommand(_ text: String, id: UUID) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        withAnimation {
            showCopiedId = id
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedId = nil
            }
        }
    }
}

struct CommandRowView: View {
    let command: CommandItem
    let isEditing: Bool
    let isCopied: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void
    
    @State private var editTitle: String = ""
    @State private var editCommand: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Title", text: $editTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Command", text: $editCommand)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                        
                        Spacer()
                        
                        Button("Cancel", action: onCancel)
                        Button("Save", action: onSave)
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(command.title)
                            .font(.headline)
                        Text(command.command)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button(action: onCopy) {
                        Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            .foregroundColor(isCopied ? .green : .accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(command.command.isEmpty)
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .onAppear {
            editTitle = command.title
            editCommand = command.command
        }
    }
}

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
