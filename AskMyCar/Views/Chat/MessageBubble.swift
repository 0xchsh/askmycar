import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            Text(message.content)
                .padding(12)
                .background(isUser ? Color.userBubble : Color.assistantBubble)
                .foregroundStyle(isUser ? .white : Color.appPrimaryText)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack {
        MessageBubble(message: ChatMessage(role: .user, content: "What oil does my car need?"))
        MessageBubble(message: ChatMessage(role: .assistant, content: "Your vehicle uses 0W-20 synthetic oil. The oil capacity is approximately 5.7 quarts with filter change."))
    }
}
