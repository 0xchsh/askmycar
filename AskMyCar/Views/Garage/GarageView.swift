import SwiftUI
import SwiftData

struct GarageView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Vehicle.createdAt, order: .reverse) private var vehicles: [Vehicle]
    @State private var viewModel = GarageViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(vehicles, id: \.id) { vehicle in
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        viewModel.setActiveVehicle(vehicle, allVehicles: vehicles, appState: appState)
                        dismiss()
                    } label: {
                        VehicleCard(vehicle: vehicle)
                    }
                    .tint(.primary)
                }
                .onDelete(perform: deleteVehicles)
            }
            .navigationTitle("Garage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showAddVehicle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddVehicle) {
                OnboardingView()
            }
            .overlay {
                if vehicles.isEmpty {
                    ContentUnavailableView(
                        "No Vehicles",
                        systemImage: "car",
                        description: Text("Add your first vehicle to get started.")
                    )
                }
            }
        }
    }

    private func deleteVehicles(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteVehicle(vehicles[index], in: modelContext, appState: appState)
        }
    }
}

#Preview {
    GarageView()
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, ChatSession.self, ChatMessage.self], inMemory: true)
}
