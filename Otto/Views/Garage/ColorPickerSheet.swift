import SwiftUI

struct ColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle
    @State private var selected: String = "default"
    @State private var availableColors: [String] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isLoading {
                    Spacer()
                    ProgressView("Loading colors...")
                    Spacer()
                } else if availableColors.isEmpty {
                    Spacer()
                    Text("No colors available")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(availableColors, id: \.self) { color in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selected = color
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(swatchColor(for: color))
                                            .frame(width: 44, height: 44)
                                            .overlay {
                                                if needsBorder(color) {
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

                                        Text(displayName(for: color))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                            .frame(height: 28)
                                    }
                                }
                                .frame(width: 70)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Button {
                    vehicle.exteriorColor = selected == "default" ? nil : selected
                    vehicle.clearCachedImageURLs()
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
        .presentationDetents([.medium])
        .task {
            await loadColors()
        }
    }

    private func loadColors() async {
        do {
            let colors = try await VehicleImageService.shared.fetchAvailableColors(for: vehicle)
            availableColors = colors
            // Pre-select current color
            if let current = vehicle.exteriorColor, colors.contains(current) {
                selected = current
            } else if colors.contains("default") {
                selected = "default"
            } else if let first = colors.first {
                selected = first
            }
        } catch {
            // Fall back to just "default"
            availableColors = ["default"]
        }
        isLoading = false
    }

    private func displayName(for color: String) -> String {
        if color == "default" { return "Default" }
        return color
    }

    private func needsBorder(_ color: String) -> Bool {
        let lower = color.lowercased()
        return lower.contains("white") || lower == "default"
    }

    /// Maps OEM color names to approximate swatch colors for the UI.
    private func swatchColor(for color: String) -> Color {
        let lower = color.lowercased()

        // Check for common color keywords in OEM names
        if lower == "default" { return Color(.systemGray4) }
        if lower.contains("white") || lower.contains("alpine") || lower.contains("mineral white") || lower.contains("glacier") { return Color(uiColor: .systemBackground) }
        if lower.contains("black") || lower.contains("sapphire") || lower.contains("obsidian") { return Color(red: 0.12, green: 0.12, blue: 0.13) }
        if lower.contains("silver") || lower.contains("platinum") { return Color(red: 0.75, green: 0.75, blue: 0.77) }
        if lower.contains("grey") || lower.contains("gray") || lower.contains("mineral") || lower.contains("graphite") || lower.contains("granite") { return Color(red: 0.45, green: 0.45, blue: 0.47) }
        if lower.contains("red") || lower.contains("melbourne") || lower.contains("flamenco") || lower.contains("tango") { return Color(red: 0.78, green: 0.14, blue: 0.14) }
        if lower.contains("blue") || lower.contains("estoril") || lower.contains("portimao") || lower.contains("marina") || lower.contains("navarra") { return Color(red: 0.20, green: 0.45, blue: 0.78) }
        if lower.contains("green") || lower.contains("verde") || lower.contains("british") { return Color(red: 0.18, green: 0.55, blue: 0.34) }
        if lower.contains("brown") || lower.contains("terra") || lower.contains("marrakesh") || lower.contains("coffee") { return Color(red: 0.45, green: 0.30, blue: 0.20) }
        if lower.contains("gold") || lower.contains("champagne") || lower.contains("sunstone") { return Color(red: 0.76, green: 0.65, blue: 0.35) }
        if lower.contains("orange") || lower.contains("sunset") || lower.contains("fire") || lower.contains("valencia") { return Color(red: 0.90, green: 0.45, blue: 0.10) }
        if lower.contains("yellow") || lower.contains("austin") || lower.contains("speed") { return Color(red: 0.92, green: 0.82, blue: 0.20) }
        if lower.contains("purple") || lower.contains("violet") || lower.contains("twilight") { return Color(red: 0.45, green: 0.25, blue: 0.65) }
        if lower.contains("beige") || lower.contains("cream") || lower.contains("cashmere") { return Color(red: 0.85, green: 0.80, blue: 0.70) }

        // Unknown color — neutral gray
        return Color(.systemGray3)
    }
}
