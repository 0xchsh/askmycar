import SwiftUI
import SwiftData

@main
struct AskMyCarApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
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
            } else if let activeVehicle = appState.activeVehicle {
                ChatView(vehicle: activeVehicle)
            } else {
                ProgressView()
            }
        }
        .sheet(isPresented: $state.showGarage) {
            GarageView()
        }
        .sheet(isPresented: $state.showSettings) {
            SettingsView()
        }
        .onAppear {
            if appState.activeVehicle == nil {
                appState.activeVehicle = vehicles.first(where: { $0.isActive }) ?? vehicles.first
            }
        }
        .onChange(of: vehicles.count) {
            if appState.activeVehicle == nil {
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
