import SwiftUI

struct VehicleAsyncImage: View {
    let vehicle: Vehicle
    var color: String? = nil
    var view: String = "right"

    @State private var imageURL: URL?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        placeholder
                    default:
                        placeholder
                            .overlay { ProgressView() }
                    }
                }
            } else if loadFailed {
                placeholder
            } else {
                placeholder
                    .overlay { ProgressView() }
            }
        }
        .task(id: TaskIdentifier(vehicleId: vehicle.id, color: color ?? vehicle.exteriorColor ?? "", view: view)) {
            await loadImage()
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemGray5), Color(.systemGray6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "car.side.fill")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color(.systemGray3))
                .scaleEffect(x: -1)
        }
        .aspectRatio(2, contentMode: .fit)
    }

    private func loadImage() async {
        // Use per-view cached URL if still valid
        if let cached = vehicle.cachedImageURL(for: view),
           color == nil || color == vehicle.exteriorColor {
            imageURL = URL(string: cached)
            return
        }

        do {
            let service = VehicleImageService.shared
            let url = try await service.fetchImageURL(for: vehicle, color: color, view: view)
            imageURL = url
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    private struct TaskIdentifier: Equatable {
        let vehicleId: UUID
        let color: String
        let view: String
    }
}
