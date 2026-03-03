import SwiftUI

struct VehicleCard: View {
    let vehicle: Vehicle
    var onRename: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Vehicle image (CGI render from imagin.studio)
            AsyncImage(url: vehicleImageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                case .failure:
                    vehicleImagePlaceholder
                default:
                    vehicleImagePlaceholder
                        .overlay {
                            ProgressView()
                        }
                }
            }

            // Vehicle info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(vehicleNickname)
                        .font(.system(size: 18, weight: .semibold))

                    Menu {
                        Button {
                            onRename()
                        } label: {
                            Label("Rename Vehicle", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete Vehicle", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.appSecondaryText)
                    }

                    if vehicle.isActive {
                        Text("Active")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }

                Text(vehicle.displayName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.appSecondaryText)
            }
        }
    }

    private var vehicleImagePlaceholder: some View {
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
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(Color(.systemGray3))
        }
        .aspectRatio(2, contentMode: .fit)
    }

    private var vehicleImageURL: URL? {
        var components = URLComponents(string: "https://cdn.imagin.studio/getimage")!
        components.queryItems = [
            URLQueryItem(name: "customer", value: "img"),
            URLQueryItem(name: "make", value: vehicle.make),
            URLQueryItem(name: "modelFamily", value: vehicle.model),
            URLQueryItem(name: "modelYear", value: "\(vehicle.year)"),
            URLQueryItem(name: "angle", value: "5")
        ]
        return components.url
    }

    private var vehicleNickname: String {
        vehicle.nickname ?? "\(vehicle.make) \(vehicle.model)"
    }
}

#Preview {
    VehicleCard(vehicle: Vehicle(make: "Honda", model: "CR-V", year: 2025, nickname: "Hugo"))
        .padding()
}
