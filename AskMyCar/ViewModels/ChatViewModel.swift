import Foundation
import SwiftData

@Observable
@MainActor
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var inputText = ""
    var isLoading = false
    var isStreaming = false
    var errorMessage: String?

    private var currentSession: ChatSession?
    private var streamTask: Task<Void, Never>?
    private let aiService = AIService()

    func loadOrCreateSession(for vehicle: Vehicle, in context: ModelContext) {
        if let existingSession = vehicle.sessions.first {
            currentSession = existingSession
            messages = existingSession.sortedMessages
        } else {
            let session = ChatSession(title: vehicle.displayName)
            session.vehicle = vehicle
            context.insert(session)
            currentSession = session
            messages = []
        }
    }

    func sendMessage(for vehicle: Vehicle, in context: ModelContext) {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        errorMessage = nil

        let userMessage = ChatMessage(role: .user, content: text)
        userMessage.session = currentSession
        context.insert(userMessage)
        messages.append(userMessage)
        currentSession?.updatedAt = Date()

        let assistantMessage = ChatMessage(role: .assistant, content: "")
        assistantMessage.session = currentSession
        context.insert(assistantMessage)
        messages.append(assistantMessage)

        isLoading = true
        isStreaming = true

        let systemPrompt = AIService.buildSystemPrompt(for: vehicle)

        var aiMessages: [AIMessage] = [
            AIMessage(role: "system", content: systemPrompt)
        ]

        for msg in messages where msg.role != .system {
            if msg.id == assistantMessage.id { continue }
            aiMessages.append(AIMessage(role: msg.role.rawValue, content: msg.content))
        }

        streamTask = Task {
            do {
                var fullResponse = ""
                let stream = await aiService.streamChat(messages: aiMessages)
                isLoading = false

                for try await chunk in stream {
                    fullResponse += chunk
                    assistantMessage.content = fullResponse
                    if let index = messages.lastIndex(where: { $0.id == assistantMessage.id }) {
                        messages[index] = assistantMessage
                    }
                }

                isStreaming = false
            } catch {
                isLoading = false
                isStreaming = false
                if assistantMessage.content.isEmpty {
                    if let index = messages.lastIndex(where: { $0.id == assistantMessage.id }) {
                        messages.remove(at: index)
                    }
                    context.delete(assistantMessage)
                }
                errorMessage = error.localizedDescription
            }
        }
    }

    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isLoading = false
        isStreaming = false
    }

    func suggestedPrompts(for vehicle: Vehicle) -> [String] {
        [
            "What's the recommended maintenance schedule?",
            "What are common issues with my \(vehicle.displayName)?",
            "What type of oil should I use?",
            "What's the tire pressure recommendation?",
            "Tell me about the safety features",
            "What's the towing capacity?"
        ]
    }
}
