import SwiftUI

struct DeleteTabView: View {
    @EnvironmentObject var appState: AppState
    let tab: TabItem
    let onDelete: () -> Void
    let onCancel: () -> Void
    
    @State private var password = ""
    @State private var showError = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delete \"\(tab.title)\"?")
                .font(.headline)
            
            if tab.tabPasswordHash != nil {
                Text("Enter password to delete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if showError {
                    Text("Incorrect password")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else {
                Text("This action cannot be undone.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Delete", action: handleDelete)
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(!canDelete)
            }
        }
        .padding()
        .frame(width: 250)
    }
    
    private var canDelete: Bool {
        tab.tabPasswordHash == nil || !password.isEmpty
    }
    
    private func handleDelete() {
        if tab.tabPasswordHash != nil {
            if appState.unlockTab(id: tab.id, password: password) {
                onDelete()
            } else {
                showError = true
                password = ""
            }
        } else {
            onDelete()
        }
    }
}