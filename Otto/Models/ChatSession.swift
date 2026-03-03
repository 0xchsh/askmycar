import Foundation
import SwiftData

@Model
final class ChatSession {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage]

    var vehicle: Vehicle?

    var sortedMessages: [ChatMessage] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }

    var previewText: String {
        let firstUserMessage = sortedMessages.first(where: { $0.role == .user })
        let text = firstUserMessage?.content ?? "New Chat"
        return text.count > 80 ? String(text.prefix(80)) + "..." : text
    }

    var lastActivityDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }

    init(title: String, vehicle: Vehicle? = nil) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = []
        self.vehicle = vehicle
    }
}
