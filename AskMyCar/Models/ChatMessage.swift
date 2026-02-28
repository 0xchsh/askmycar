import Foundation
import SwiftData

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

@Model
final class ChatMessage {
    var id: UUID
    var role: MessageRole
    var content: String
    var createdAt: Date
    var session: ChatSession?

    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.createdAt = Date()
    }
}
