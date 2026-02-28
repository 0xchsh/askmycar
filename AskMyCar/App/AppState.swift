import SwiftUI

@Observable
final class AppState {
    var activeVehicle: Vehicle?
    var showGarage = false
    var showSettings = false
    var errorMessage: String?
}
