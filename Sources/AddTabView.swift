import SwiftUI

struct AddTabView: View {
    @State private var title: String = ""
    @State private var type: TabType = .command
    @State private var tabPassword: String = ""
    
    var onAdd: (String, TabType, String?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Tab")
                .font(.headline)
            
            TextField("Tab Name", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Picker("Type", selection: $type) {
                Text("Command").tag(TabType.command)
                Text("Note").tag(TabType.note)
                Text("Password").tag(TabType.password)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            SecureField("Tab Password (optional)", text: $tabPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Add") {
                if !title.isEmpty {
                    onAdd(title, type, tabPassword.isEmpty ? nil : tabPassword)
                }
            }
            .disabled(title.isEmpty)
            .keyboardShortcut(.defaultAction)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(width: 250)
    }
}