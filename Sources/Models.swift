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
    var secret: String
    var isEncrypted: Bool
    
    init(id: UUID = UUID(), name: String, secret: String, isEncrypted: Bool) {
        self.id = id
        self.name = name
        self.secret = secret
        self.isEncrypted = isEncrypted
    }
}

struct TabItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var type: TabType
    var content: String
    var commands: [CommandItem]
    var passwords: [PasswordItem]
    var tabPasswordHash: String?
    var tabPasswordSalt: Data?
    
    init(id: UUID = UUID(), title: String, type: TabType, content: String = "", commands: [CommandItem] = [], passwords: [PasswordItem] = [], tabPasswordHash: String? = nil, tabPasswordSalt: Data? = nil) {
        self.id = id
        self.title = title
        self.type = type
        self.content = content
        self.commands = commands
        self.passwords = passwords
        self.tabPasswordHash = tabPasswordHash
        self.tabPasswordSalt = tabPasswordSalt
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
    
    func hashPassword(_ password: String) -> (hash: String, salt: Data) {
        let salt = generateSalt()
        let passwordData = Data(password.utf8)
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: salt,
            info: Data("AliasTabPassword".utf8),
            outputByteCount: 32
        )
        let hashData = derivedKey.withUnsafeBytes { Data($0) }
        return (hashData.base64EncodedString(), salt)
    }
    
    func verifyPassword(_ password: String, hash: String, salt: Data) -> Bool {
        let passwordData = Data(password.utf8)
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: salt,
            info: Data("AliasTabPassword".utf8),
            outputByteCount: 32
        )
        let computedHashData = derivedKey.withUnsafeBytes { Data($0) }
        return computedHashData.base64EncodedString() == hash
    }
}

class AppState: ObservableObject {
    @Published var tabs: [TabItem] = [] {
        didSet {
            save()
        }
    }
    
    @Published var selectedTabId: UUID?
    @Published var unlockedTabIds: Set<UUID> = []
    
    private let userDefaultsKey = "com.alias.app.tabs"
    
    init() {
        load()
    }
    
    func isTabUnlocked(id: UUID) -> Bool {
        return unlockedTabIds.contains(id)
    }
    
    func unlockTab(id: UUID, password: String) -> Bool {
        guard let tabIndex = tabs.firstIndex(where: { $0.id == id }),
              let hash = tabs[tabIndex].tabPasswordHash,
              let salt = tabs[tabIndex].tabPasswordSalt else {
            return false
        }
        
        if CryptoService.shared.verifyPassword(password, hash: hash, salt: salt) {
            unlockedTabIds.insert(id)
            return true
        }
        return false
    }
    
    func lockTab(id: UUID) {
        unlockedTabIds.remove(id)
    }
    
    func setTabPassword(id: UUID, password: String?) {
        if let index = tabs.firstIndex(where: { $0.id == id }) {
            if let password = password, !password.isEmpty {
                let (hash, salt) = CryptoService.shared.hashPassword(password)
                tabs[index].tabPasswordHash = hash
                tabs[index].tabPasswordSalt = salt
            } else {
                tabs[index].tabPasswordHash = nil
                tabs[index].tabPasswordSalt = nil
            }
        }
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
        if encryptionPassword == nil || encryptionPassword?.isEmpty == true {
            let newItem = PasswordItem(name: name, secret: secret, isEncrypted: false)
            if let index = tabs.firstIndex(where: { $0.id == tabId }) {
                tabs[index].passwords.append(newItem)
            }
        } else {
            do {
                let (encrypted, salt) = try CryptoService.shared.encrypt(secret: secret, using: encryptionPassword!)
                let newItem = PasswordItem(name: name, secret: "\(salt.base64EncodedString()):\(encrypted.base64EncodedString())", isEncrypted: true)
                if let index = tabs.firstIndex(where: { $0.id == tabId }) {
                    tabs[index].passwords.append(newItem)
                }
            } catch {
                print("Failed to encrypt password: \(error)")
            }
        }
    }
    
    func deletePasswordItem(from tabId: UUID, itemId: UUID) {
        if let index = tabs.firstIndex(where: { $0.id == tabId }) {
            tabs[index].passwords.removeAll { $0.id == itemId }
        }
    }
    
    func getPassword(tabId: UUID, itemId: UUID, userPassword: String? = nil) -> String? {
        guard let tabIndex = tabs.firstIndex(where: { $0.id == tabId }),
              let itemIndex = tabs[tabIndex].passwords.firstIndex(where: { $0.id == itemId }) else {
            return nil
        }
        
        let item = tabs[tabIndex].passwords[itemIndex]
        
        if item.isEncrypted {
            guard let password = userPassword else { return nil }
            do {
                let parts = item.secret.split(separator: ":", maxSplits: 1)
                guard parts.count == 2 else { return nil }
                let salt = Data(base64Encoded: String(parts[0]))!
                let encryptedData = Data(base64Encoded: String(parts[1]))!
                return try CryptoService.shared.decrypt(encryptedData: encryptedData, salt: salt, using: password)
            } catch {
                return nil
            }
        } else {
            return item.secret
        }
    }
    
    func deleteTab(id: UUID) {
        tabs.removeAll { $0.id == id }
        if selectedTabId == id {
            selectedTabId = tabs.first?.id
        }
        unlockedTabIds.remove(id)
    }
    
    func moveTab(from source: IndexSet, to destination: Int) {
        var tabsArray = tabs
        let sourceIndex = source.first!
        
        let tab = tabsArray.remove(at: sourceIndex)
        tabsArray.insert(tab, at: min(destination, tabsArray.count))
        tabs = tabsArray
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
