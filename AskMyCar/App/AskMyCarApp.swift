import SwiftUI
import SwiftData

@main
struct AskMyCarApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .fontDesign(.rounded)
        }
        .modelContainer(for: [Vehicle.self, ChatSession.self, ChatMessage.self])
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Vehicle.createdAt) private var vehicles: [Vehicle]

    var body: some View {
        @Bindable var state = appState

        Group {
            if vehicles.isEmpty {
                OnboardingView()
            } else {
                NavigationStack(path: $state.navigationPath) {
                    ChatHistoryView()
                        .navigationDestination(for: ChatSession.self) { session in
                            ChatView(session: session)
                        }
                }
            }
        }
        .onAppear {
            if appState.activeVehicle == nil {
                appState.activeVehicle = vehicles.first(where: { $0.isActive }) ?? vehicles.first
            }
        }
        .onChange(of: vehicles.count) { oldCount, newCount in
            // First vehicle just added via onboarding
            if oldCount == 0 && newCount > 0 {
                let vehicle = vehicles.first(where: { $0.isActive }) ?? vehicles.first
                appState.activeVehicle = vehicle

                if let vehicle, appState.navigationPath.isEmpty {
                    let session = ChatSession(title: "New Chat", vehicle: vehicle)
                    modelContext.insert(session)
                    appState.navigationPath = [session]
                }
            } else if appState.activeVehicle == nil {
                appState.activeVehicle = vehicles.first(where: { $0.isActive }) ?? vehicles.first
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, ChatSession.self, ChatMessage.self], inMemory: true)
}
