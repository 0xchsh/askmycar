import Foundation
import SwiftData

@Observable
@MainActor
final class GarageViewModel {
    var showAddVehicle = false

    func setActiveVehicle(_ vehicle: Vehicle, allVehicles: [Vehicle], appState: AppState) {
        for v in allVehicles {
            v.isActive = false
        }
        vehicle.isActive = true
        appState.activeVehicle = vehicle
    }

    func deleteVehicle(_ vehicle: Vehicle, in context: ModelContext, appState: AppState) {
        let wasActive = vehicle.isActive
        context.delete(vehicle)

        if wasActive {
            let descriptor = FetchDescriptor<Vehicle>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            if let remaining = try? context.fetch(descriptor).first {
                remaining.isActive = true
                appState.activeVehicle = remaining
            } else {
                appState.activeVehicle = nil
            }
        }
    }
}
