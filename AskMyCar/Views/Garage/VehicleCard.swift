import SwiftUI

struct VehicleCard: View {
    let vehicle: Vehicle

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.title2)
                .foregroundStyle(Color.appAccent)
                .frame(width: 44, height: 44)
                .background(Color.appAccent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(vehicle.displayName)
                        .font(.headline)

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

                HStack(spacing: 8) {
                    if let trim = vehicle.trim {
                        Text(trim)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let vin = vehicle.vin {
                        Text(maskedVIN(vin))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func maskedVIN(_ vin: String) -> String {
        guard vin.count == 17 else { return vin }
        let prefix = String(vin.prefix(4))
        let suffix = String(vin.suffix(4))
        return "\(prefix)...\(suffix)"
    }
}

#Preview {
    VehicleCard(vehicle: Vehicle(make: "Toyota", model: "Camry", year: 2024, vin: "1HGBH41JXMN109186", trim: "XSE"))
}
