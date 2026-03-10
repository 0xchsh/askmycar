import SwiftUI
import SwiftData

@Observable
final class AppState {
    var activeVehicle: Vehicle?
    var showGarage = false
    var showSidebar = false
    var activeSession: ChatSession?
    var errorMessage: String?

    let subscriptionManager = SubscriptionManager()

    /// Tracks when the app last entered the background, for fresh-chat-on-return logic.
    var lastBackgroundDate: Date?

    /// How long the app must be in the background before we create a fresh chat (30 min).
    static let freshChatThreshold: TimeInterval = 30 * 60
}
