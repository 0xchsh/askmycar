import SwiftUI

struct SuggestedPrompts: View {
    let prompts: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        Haptics.impact(.light)
                        onSelect(prompt)
                    } label: {
                        Text(prompt)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.appSecondaryBackground)
                            .foregroundStyle(Color.appPrimaryText)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white, location: 0.04),
                    .init(color: .white, location: 0.96),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

#Preview {
    SuggestedPrompts(prompts: [
        "What oil should I use?",
        "Maintenance schedule",
        "Common issues"
    ]) { prompt in
        print(prompt)
    }
}
