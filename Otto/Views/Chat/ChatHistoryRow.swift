import SwiftUI
import SwiftData

struct ChatHistoryRow: View {
    let session: ChatSession
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let vehicle = session.vehicle {
                    VehicleAsyncImage(vehicle: vehicle, view: "front")
                } else {
                    Image(systemName: "car.side.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(.systemGray3))
                        .scaleEffect(x: -1)
                }
            }
            .frame(width: 56, height: 40)

            Text(session.previewText)
                .font(.body)
                .foregroundStyle(Color.appPrimaryText)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            isActive
            ? Color.appAccent.opacity(0.12)
            : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

}
