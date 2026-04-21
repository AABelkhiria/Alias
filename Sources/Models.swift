import Foundation
import Combine

enum TabType: String, Codable {
    case command
    case note
}

struct TabItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var type: TabType
    var content: String
    
    init(id: UUID = UUID(), title: String, type: TabType, content: String = "") {
        self.id = id
        self.title = title
        self.type = type
        self.content = content
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
            // Default tabs
            let defaultCmd = TabItem(title: "SSH Server", type: .command, content: "ssh user@myserver.com")
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
        let newTab = TabItem(title: title, type: type)
        tabs.append(newTab)
        selectedTabId = newTab.id
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
