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

struct PasswordTabView: View {
    @EnvironmentObject var appState: AppState
    let tab: TabItem
    
    @State private var showingAddSheet = false
    @State private var newName = ""
    @State private var newPassword = ""
    @State private var revealingItemId: UUID?
    @State private var decryptedPasswords: [UUID: String] = [:]
    @State private var revealPasswordError: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(tab.passwords) { item in
                        PasswordRowView(
                            item: item,
                            isRevealed: revealingItemId == item.id,
                            revealedPassword: decryptedPasswords[item.id],
                            onReveal: { promptPassword(for: item.id) },
                            onDelete: { appState.deletePasswordItem(from: tab.id, itemId: item.id) },
                            onHide: {
                                withAnimation {
                                    revealingItemId = nil
                                    decryptedPasswords.removeValue(forKey: item.id)
                                }
                            }
                        )
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                appState.deletePasswordItem(from: tab.id, itemId: item.id)
                            }
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                    Text("Add Password")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .padding()
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .sheet(isPresented: $showingAddSheet) {
            AddPasswordSheet(
                name: $newName,
                password: $newPassword,
                onSave: {
                    if !newName.isEmpty && !newPassword.isEmpty {
                        appState.addPasswordItem(to: tab.id, name: newName, password: newPassword)
                        newName = ""
                        newPassword = ""
                        showingAddSheet = false
                    }
                },
                onCancel: {
                    newName = ""
                    newPassword = ""
                    showingAddSheet = false
                }
            )
        }
        .onChange(of: tab.id) { _ in
            revealingItemId = nil
            decryptedPasswords.removeAll()
        }
    }
    
    private func promptPassword(for itemId: UUID) {
        let alert = NSAlert()
        alert.messageText = "Enter Password"
        alert.informativeText = "Enter the password to decrypt this entry."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Reveal")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let password = input.stringValue
            if let decrypted = appState.decryptPassword(tabId: tab.id, itemId: itemId, userPassword: password) {
                withAnimation {
                    revealingItemId = itemId
                    decryptedPasswords[itemId] = decrypted
                }
            } else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Incorrect Password"
                errorAlert.informativeText = "The password you entered is incorrect."
                errorAlert.alertStyle = .warning
                errorAlert.addButton(withTitle: "OK")
                errorAlert.runModal()
            }
        }
    }
}

struct PasswordRowView: View {
    let item: PasswordItem
    let isRevealed: Bool
    let revealedPassword: String?
    let onReveal: () -> Void
    let onDelete: () -> Void
    let onHide: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                if isRevealed, let password = revealedPassword {
                    Text(password)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                } else {
                    Text("••••••••")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isRevealed {
                Button(action: onHide) {
                    Image(systemName: "eye.slash")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            } else {
                Button(action: onReveal) {
                    Image(systemName: "eye")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
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

struct AddPasswordSheet: View {
    @Binding var name: String
    @Binding var password: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Password")
                .font(.headline)
            
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty || password.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
