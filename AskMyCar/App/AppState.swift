import SwiftUI

@Observable
final class AppState {
    var activeVehicle: Vehicle?
    var showGarage = false
    var navigationPath: [ChatSession] = []
    var errorMessage: String?
}
