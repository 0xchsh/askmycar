import SwiftUI

struct ColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle
    @State private var selected: VehicleColor = .white

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Live preview
                AsyncImage(url: previewURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    default:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                            .aspectRatio(2, contentMode: .fit)
                            .overlay { ProgressView() }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

                // Color swatches
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exterior Color")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(VehicleColor.allCases) { color in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selected = color
                                }
                            } label: {
                                Circle()
                                    .fill(color.swatchColor)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if color.needsBorder {
                                            Circle()
                                                .strokeBorder(Color(.systemGray4), lineWidth: 1.5)
                                        }
                                    }
                                    .overlay {
                                        if selected == color {
                                            Circle()
                                                .strokeBorder(Color.appAccent, lineWidth: 2.5)
                                                .frame(width: 52, height: 52)
                                        }
                                    }
                            }
                            .frame(width: 52, height: 52)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    vehicle.exteriorColor = selected.paintDescription
                    dismiss()
                } label: {
                    Text("Save")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appAccent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Change Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            if let existing = vehicle.exteriorColor,
               let match = VehicleColor(rawValue: existing) {
                selected = match
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var previewURL: URL? {
        var components = URLComponents(string: "https://cdn.imagin.studio/getimage")!
        var items = [
            URLQueryItem(name: "customer", value: "hrjavascript-masede"),
            URLQueryItem(name: "make", value: vehicle.make),
            URLQueryItem(name: "modelFamily", value: vehicle.model),
            URLQueryItem(name: "modelYear", value: "\(vehicle.year)"),
            URLQueryItem(name: "angle", value: "5"),
            URLQueryItem(name: "paintDescription", value: selected.paintDescription)
        ]
        components.queryItems = items
        return components.url
    }
}
