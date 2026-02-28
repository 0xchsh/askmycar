import SwiftUI
import SwiftData

struct ChatHistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatSession.updatedAt, order: .reverse) private var sessions: [ChatSession]
    @State private var showSettings = false

    var body: some View {
        List {
            ForEach(sessions, id: \.id) { session in
                NavigationLink(value: session) {
                    ChatHistoryRow(session: session)
                }
            }
            .onDelete(perform: deleteSessions)
        }
        .navigationTitle("AskMyCar")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    createNewSession()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                showSettings = true
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .overlay {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Conversations",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Tap + to start a new chat about your vehicle.")
                )
            }
        }
    }

    private func createNewSession() {
        guard let vehicle = appState.activeVehicle else { return }
        let session = ChatSession(title: "New Chat", vehicle: vehicle)
        modelContext.insert(session)
        appState.navigationPath.append(session)
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }
}

#Preview {
    NavigationStack {
        ChatHistoryView()
    }
    .environment(AppState())
    .modelContainer(for: [Vehicle.self, ChatSession.self, ChatMessage.self], inMemory: true)
}
