import Foundation
import Combine
import CryptoKit

enum TabType: String, Codable {
    case command
    case note
    case password
}

struct CommandItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var command: String
    
    init(id: UUID = UUID(), title: String, command: String) {
        self.id = id
        self.title = title
        self.command = command
    }
}

struct PasswordItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var encryptedSecret: Data
    var salt: Data
    var usesSeparateEncryptionPassword: Bool
    
    init(id: UUID = UUID(), name: String, encryptedSecret: Data, salt: Data, usesSeparateEncryptionPassword: Bool = false) {
        self.id = id
        self.name = name
        self.encryptedSecret = encryptedSecret
        self.salt = salt
        self.usesSeparateEncryptionPassword = usesSeparateEncryptionPassword
    }
}

struct TabItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var type: TabType
    var content: String
    var commands: [CommandItem]
    var passwords: [PasswordItem]
    
    init(id: UUID = UUID(), title: String, type: TabType, content: String = "", commands: [CommandItem] = [], passwords: [PasswordItem] = []) {
        self.id = id
        self.title = title
        self.type = type
        self.content = content
        self.commands = commands
        self.passwords = passwords
    }
}

enum CryptoError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidPassword
}

class CryptoService {
    static let shared = CryptoService()
    
    private let iterations = 100_000
    
    private init() {}
    
    func deriveKey(password: String, salt: Data) -> SymmetricKey {
        let passwordData = Data(password.utf8)
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: salt,
            info: Data("AliasPasswordVault".utf8),
            outputByteCount: 32
        )
        return derivedKey
    }
    
    func encrypt(secret: String, using userPassword: String) throws -> (encrypted: Data, salt: Data) {
        let salt = generateSalt()
        let key = deriveKey(password: userPassword, salt: salt)
        let secretData = Data(secret.utf8)
        
        guard let sealedBox = try? AES.GCM.seal(secretData, using: key) else {
            throw CryptoError.encryptionFailed
        }
        
        return (sealedBox.combined!, salt)
    }
    
    func decrypt(encryptedData: Data, salt: Data, using userPassword: String) throws -> String {
        let key = deriveKey(password: userPassword, salt: salt)
        
        guard let sealedBox = try? AES.GCM.SealedBox(combined: encryptedData),
              let decryptedData = try? AES.GCM.open(sealedBox, using: key),
              let decryptedPassword = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }
        
        return decryptedPassword
    }
    
    private func generateSalt() -> Data {
        var salt = Data(count: 32)
        _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
        return salt
    }
}

class AppState: ObservableObject {
    @Published var tabs: [TabItem] = [] {
        didSet {
            save()
        }
    }
    
    @Published var selectedTabId: UUID?
    
    private let userDefaultsKey = "com.alias.app.tabs"
    
    init() {
        load()
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([TabItem].self, from: data) {
            self.tabs = decoded
            if !decoded.isEmpty {
                self.selectedTabId = decoded.first?.id
            }
        } else {
            let defaultCmd = TabItem(
                title: "Server Commands",
                type: .command,
                commands: [
                    CommandItem(title: "SSH Server", command: "ssh user@myserver.com"),
                    CommandItem(title: "SSH with Key", command: "ssh -i ~/.ssh/key user@server")
                ]
            )
            let defaultNote = TabItem(title: "Scratchpad", type: .note, content: "My quick notes...")
            self.tabs = [defaultCmd, defaultNote]
            self.selectedTabId = defaultCmd.id
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(tabs) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func addTab(title: String, type: TabType) {
        var newTab = TabItem(title: title, type: type)
        if type == .command {
            newTab.commands = [CommandItem(title: "New Command", command: "")]
        }
        tabs.append(newTab)
        selectedTabId = newTab.id
    }
    
    func addCommand(to tabId: UUID) {
        if let index = tabs.firstIndex(where: { $0.id == tabId }) {
            tabs[index].commands.append(CommandItem(title: "New Command", command: ""))
        }
    }
    
    func deleteCommand(from tabId: UUID, commandId: UUID) {
        if let index = tabs.firstIndex(where: { $0.id == tabId }) {
            tabs[index].commands.removeAll { $0.id == commandId }
            if tabs[index].commands.isEmpty {
                tabs[index].commands.append(CommandItem(title: "New Command", command: ""))
            }
        }
    }
    
    func updateCommand(tabId: UUID, commandId: UUID, title: String, command: String) {
        if let tabIndex = tabs.firstIndex(where: { $0.id == tabId }),
           let cmdIndex = tabs[tabIndex].commands.firstIndex(where: { $0.id == commandId }) {
            tabs[tabIndex].commands[cmdIndex].title = title
            tabs[tabIndex].commands[cmdIndex].command = command
        }
    }
    
    func addPasswordItem(to tabId: UUID, name: String, secret: String, encryptionPassword: String?) {
        do {
            let keyPassword = encryptionPassword ?? secret
            let usesSeparate = encryptionPassword != nil
            let (encrypted, salt) = try CryptoService.shared.encrypt(secret: secret, using: keyPassword)
            let newItem = PasswordItem(name: name, encryptedSecret: encrypted, salt: salt, usesSeparateEncryptionPassword: usesSeparate)
            if let index = tabs.firstIndex(where: { $0.id == tabId }) {
                tabs[index].passwords.append(newItem)
            }
        } catch {
            print("Failed to encrypt password: \(error)")
        }
    }
    
    func deletePasswordItem(from tabId: UUID, itemId: UUID) {
        if let index = tabs.firstIndex(where: { $0.id == tabId }) {
            tabs[index].passwords.removeAll { $0.id == itemId }
        }
    }
    
    func decryptPassword(tabId: UUID, itemId: UUID, userPassword: String) -> String? {
        guard let tabIndex = tabs.firstIndex(where: { $0.id == tabId }),
              let itemIndex = tabs[tabIndex].passwords.firstIndex(where: { $0.id == itemId }) else {
            return nil
        }
        
        let item = tabs[tabIndex].passwords[itemIndex]
        
        do {
            return try CryptoService.shared.decrypt(
                encryptedData: item.encryptedSecret,
                salt: item.salt,
                using: userPassword
            )
        } catch {
            return nil
        }
    }
    
    func deleteTab(id: UUID) {
        tabs.removeAll { $0.id == id }
        if selectedTabId == id {
            selectedTabId = tabs.first?.id
        }
    }
    
    func updateTab(id: UUID, newTitle: String) {
        if let index = tabs.firstIndex(where: { $0.id == id }) {
            tabs[index].title = newTitle
        }
    }
    
    func updateContent(id: UUID, newContent: String) {
         if let index = tabs.firstIndex(where: { $0.id == id }) {
             tabs[index].content = newContent
         }
    }
}
