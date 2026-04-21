import Foundation
import Combine

enum TabType: String, Codable {
    case command
    case note
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

struct TabItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var type: TabType
    var content: String
    var commands: [CommandItem]
    
    init(id: UUID = UUID(), title: String, type: TabType, content: String = "", commands: [CommandItem] = []) {
        self.id = id
        self.title = title
        self.type = type
        self.content = content
        self.commands = commands
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
