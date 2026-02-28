import SwiftUI
import SwiftData

struct ChatHistoryRow: View {
    let session: ChatSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.title3)
                .foregroundStyle(Color.appAccent)
                .frame(width: 36, height: 36)
                .background(Color.appSecondaryBackground)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(session.previewText)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let vehicle = session.vehicle {
                        Text(vehicle.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\u{00B7}")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(session.lastActivityDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
