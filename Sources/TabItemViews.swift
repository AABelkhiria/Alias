import SwiftUI

struct CommandTabView: View {
    @EnvironmentObject var appState: AppState
    let tab: TabItem
    
    @State private var editingCommandId: UUID?
    @State private var editTitle: String = ""
    @State private var editCommand: String = ""
    @State private var showCopiedId: UUID?
    
    @State private var showingAddPopover = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(tab.commands) { command in
                        CommandRowView(
                            tabId: tab.id,
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
                    showingAddPopover = true
                }) {
                    Image(systemName: "plus")
                    Text("Add Command")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .padding()
                .popover(isPresented: $showingAddPopover, arrowEdge: .bottom) {
                    AddCommandView { title, command in
                        appState.addCommand(to: tab.id, title: title, command: command)
                        showingAddPopover = false
                    } onCancel: {
                        showingAddPopover = false
                    }
                }
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

struct AddCommandView: View {
    @State private var title: String = ""
    @State private var command: String = ""
    
    var onAdd: (String, String) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Command")
                .font(.headline)
            
            TextField("Name", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Command", text: $command)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(.body, design: .monospaced))
            
            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Add") {
                    onAdd(title, command)
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty || command.isEmpty)
            }
        }
        .padding()
        .frame(width: 250)
    }
}

struct DeleteCommandView: View {
    let title: String
    var onDelete: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delete \"\(title)\"?")
                .font(.headline)
            
            Text("This action cannot be undone.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Delete", action: onDelete)
                    .buttonStyle(.bordered)
                    .tint(.red)
            }
        }
        .padding()
        .frame(width: 200)
    }
}

struct CommandRowView: View {
    @EnvironmentObject var appState: AppState
    let tabId: UUID
    let command: CommandItem
    let isEditing: Bool
    let isCopied: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var editTitle: String = ""
    @State private var editCommand: String = ""
    @State private var showingDeletePopover = false
    
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
                        // Command text is now hidden
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
                    
                    Button(action: { showingDeletePopover = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingDeletePopover, arrowEdge: .bottom) {
                        DeleteCommandView(title: command.title) {
                            appState.deleteCommand(from: tabId, commandId: command.id)
                            showingDeletePopover = false
                        } onCancel: {
                            showingDeletePopover = false
                        }
                    }
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
    
    @State private var showingAddForm = false
    @State private var newName = ""
    @State private var newSecret = ""
    @State private var newEncryptionPassword = ""
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(tab.passwords) { item in
                        PasswordRowView(
                            item: item,
                            getSecretFn: { password in
                                appState.getPassword(tabId: tab.id, itemId: item.id, userPassword: password)
                            },
                            deleteFn: {
                                appState.deletePasswordItem(from: tab.id, itemId: item.id)
                            }
                        )
                    }
                    
                    if showingAddForm {
                        AddPasswordForm(
                            name: $newName,
                            secret: $newSecret,
                            encryptionPassword: $newEncryptionPassword,
                            onSave: {
                                if !newName.isEmpty && !newSecret.isEmpty {
                                    let encPassword = newEncryptionPassword.isEmpty ? nil : newEncryptionPassword
                                    appState.addPasswordItem(to: tab.id, name: newName, secret: newSecret, encryptionPassword: encPassword)
                                    newName = ""
                                    newSecret = ""
                                    newEncryptionPassword = ""
                                    showingAddForm = false
                                }
                            },
                            onCancel: {
                                newName = ""
                                newSecret = ""
                                newEncryptionPassword = ""
                                showingAddForm = false
                            }
                        )
                    }
                }
                .padding()
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button(action: { showingAddForm = true }) {
                    Image(systemName: "plus")
                    Text("Add Password")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .padding()
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onChange(of: tab.id) { _ in
            showingAddForm = false
        }
    }
}

enum PasswordRowState {
    case hidden
    case revealForm
    case revealed
    case deleteForm
    case copyForm
}

struct PasswordRowView: View {
    let item: PasswordItem
    let getSecretFn: (String?) -> String?
    let deleteFn: () -> Void
    
    @State private var state: PasswordRowState = .hidden
    @State private var passwordInput: String = ""
    @State private var decryptedPassword: String = ""
    @State private var showCopied: Bool = false
    @State private var showError: Bool = false
    
    private var isEncrypted: Bool { item.isEncrypted }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch state {
            case .hidden:
                hiddenView
            case .revealForm:
                revealFormView
            case .revealed:
                revealedView
            case .deleteForm:
                deleteFormView
            case .copyForm:
                copyFormView
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(state == .revealForm || state == .deleteForm || state == .copyForm ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: state == .revealForm || state == .deleteForm || state == .copyForm ? 2 : 1)
        )
    }
    
    private var hiddenView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text("••••••••")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                if isEncrypted {
                    state = .revealForm
                } else {
                    if let decrypted = getSecretFn(nil) {
                        decryptedPassword = decrypted
                        withAnimation { state = .revealed }
                    }
                }
            }) {
                Image(systemName: "eye")
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
            
            Button(action: { state = .deleteForm }) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
            
            Button(action: {
                if isEncrypted {
                    state = .copyForm
                } else {
                    if let decrypted = getSecretFn(nil) {
                        copyToClipboard(decrypted)
                        withAnimation {
                            showCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showCopied = false
                            }
                        }
                    }
                }
            }) {
                Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
            }
            .buttonStyle(.plain)
            .foregroundColor(showCopied ? .green : .accentColor)
        }
    }
    
    private var revealFormView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEncrypted {
                Text("Enter password to reveal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    SecureField("Password", text: $passwordInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Reveal") {
                        if let decrypted = getSecretFn(passwordInput) {
                            decryptedPassword = decrypted
                            passwordInput = ""
                            withAnimation {
                                state = .revealed
                            }
                        } else {
                            showError = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(passwordInput.isEmpty)
                    
                    Button("Cancel") {
                        passwordInput = ""
                        state = .hidden
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                
                if showError {
                    Text("Incorrect password")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else {
                Button("Reveal (no password)") {
                    if let decrypted = getSecretFn(nil) {
                        decryptedPassword = decrypted
                        withAnimation {
                            state = .revealed
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var revealedView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text(decryptedPassword)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                decryptedPassword = ""
                state = .hidden
            }) {
                Image(systemName: "eye.slash")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            
            Button(action: { state = .deleteForm }) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
            
            Button(action: {
                copyToClipboard(decryptedPassword)
            }) {
                Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
            }
            .buttonStyle(.plain)
            .foregroundColor(showCopied ? .green : .accentColor)
        }
    }
    
    private var deleteFormView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEncrypted {
                Text("Enter password to delete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    SecureField("Password", text: $passwordInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Delete") {
                        if let decrypted = getSecretFn(passwordInput) {
                            passwordInput = ""
                            decryptedPassword = decrypted
                            deleteFn()
                        } else {
                            showError = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(passwordInput.isEmpty)
                    
                    Button("Cancel") {
                        passwordInput = ""
                        state = .hidden
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                
                if showError {
                    Text("Incorrect password")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else {
                Text("Delete this entry?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button("Cancel") {
                        state = .hidden
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Delete") {
                        deleteFn()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var copyFormView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEncrypted {
                Text("Enter password to copy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    SecureField("Password", text: $passwordInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Copy") {
                        if let decrypted = getSecretFn(passwordInput) {
                            copyToClipboard(decrypted)
                            passwordInput = ""
                            state = .hidden
                        } else {
                            showError = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(passwordInput.isEmpty)
                    
                    Button("Cancel") {
                        passwordInput = ""
                        state = .hidden
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                
                if showError {
                    Text("Incorrect password")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else {
                Button("Copy (no password)") {
                    if let decrypted = getSecretFn(nil) {
                        copyToClipboard(decrypted)
                        state = .hidden
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    state = .hidden
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        withAnimation {
            showCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopied = false
            }
        }
    }
}

struct AddPasswordForm: View {
    @Binding var name: String
    @Binding var secret: String
    @Binding var encryptionPassword: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Password")
                .font(.headline)
            
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Secret/Key", text: $secret)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Encryption Password (optional)", text: $encryptionPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Save", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty || secret.isEmpty)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.5), lineWidth: 2)
        )
    }
}
