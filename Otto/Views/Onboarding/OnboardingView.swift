import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Vehicle.createdAt) private var vehicles: [Vehicle]
    @State private var viewModel = OnboardingViewModel()
    @State private var showIntro = true
    @State private var showMakePicker = false
    @State private var showModelPicker = false

    private var isFirstVehicle: Bool { vehicles.isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if isFirstVehicle && showIntro {
                    introView
                        .transition(.move(edge: .leading))
                } else {
                    addVehicleView
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showIntro)
        }
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "car.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.appAccent)

            VStack(spacing: 12) {
                Text("Welcome to Otto")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Your AI-powered vehicle assistant")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                featureBullet(icon: "bubble.left.and.text.bubble.right", text: "Ask anything about your car")
                featureBullet(icon: "wrench.and.screwdriver", text: "Track maintenance schedules")
                featureBullet(icon: "exclamationmark.triangle", text: "Stay on top of recalls & warranties")
            }
            .padding(.horizontal)

            Spacer()

            Button {
                withAnimation { showIntro = false }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appAccent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private func featureBullet(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.appAccent)
                .frame(width: 28)
            Text(text)
                .font(.body)
        }
    }

    // MARK: - Add Vehicle

    private var addVehicleView: some View {
        VStack(spacing: 0) {
            Picker("Input Mode", selection: $viewModel.inputMode) {
                ForEach(VehicleInputMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                VStack(spacing: 16) {
                    switch viewModel.inputMode {
                    case .vin:
                        vinContent
                    case .ymm:
                        ymmContent
                    }

                    colorPicker

                    nicknameField
                }
                .padding(.horizontal)
                .padding(.bottom)
            }

            addButton
                .padding()
        }
        .navigationTitle("Add Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isFirstVehicle {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .sheet(isPresented: $showMakePicker) {
            SearchablePickerSheet(
                title: "Select Make",
                items: VehicleData.makes,
                selection: $viewModel.make
            )
        }
        .sheet(isPresented: $showModelPicker) {
            SearchablePickerSheet(
                title: "Select Model",
                items: VehicleData.models(for: viewModel.make),
                selection: $viewModel.model
            )
        }
    }

    // MARK: - VIN Content

    private var vinContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Vehicle Identification Number is a 17-character code found on your dashboard or door jamb.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .trailing, spacing: 8) {
                TextField("e.g. 1HGBH41JXMN109186", text: $viewModel.vinText)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .formRowStyle()
                    .onChange(of: viewModel.vinText) { _, newValue in
                        viewModel.vinText = viewModel.filterVINInput(newValue)
                    }

                HStack {
                    if let error = viewModel.vinError {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - YMM Content

    private var ymmContent: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Year")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Year", selection: $viewModel.year) {
                    ForEach(yearRange, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.menu)
            }
            .formRowStyle()

            Button { showMakePicker = true } label: {
                HStack {
                    Text(viewModel.make.isEmpty ? "Make (e.g. Toyota)" : viewModel.make)
                        .foregroundStyle(viewModel.make.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .formRowStyle()
            }

            Button { showModelPicker = true } label: {
                HStack {
                    Text(viewModel.model.isEmpty ? "Model (e.g. Camry)" : viewModel.model)
                        .foregroundStyle(viewModel.model.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .formRowStyle()
            }
            .disabled(viewModel.make.isEmpty)
            .opacity(viewModel.make.isEmpty ? 0.5 : 1)

            TextField("Trim (optional, e.g. XSE)", text: $viewModel.trim)
                .textInputAutocapitalization(.characters)
                .formRowStyle()
        }
    }

    // MARK: - Nickname

    private var nicknameField: some View {
        TextField("Nickname (optional, e.g. Hugo)", text: $viewModel.nickname)
            .textInputAutocapitalization(.words)
            .formRowStyle()
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exterior Color")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(VehicleColor.allCases) { color in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedColor = color
                            }
                        } label: {
                            Circle()
                                .fill(color.swatchColor)
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if color.needsBorder {
                                        Circle()
                                            .strokeBorder(Color(.systemGray4), lineWidth: 1.5)
                                    }
                                }
                                .overlay {
                                    if viewModel.selectedColor == color {
                                        Circle()
                                            .strokeBorder(Color.appAccent, lineWidth: 2.5)
                                            .frame(width: 44, height: 44)
                                    }
                                }
                        }
                        .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            Task {
                let success = await viewModel.addVehicle(in: modelContext, appState: appState)
                if success {
                    appState.showGarage = false
                    dismiss()
                }
            }
        } label: {
            HStack {
                if viewModel.isDecodingVIN && viewModel.inputMode == .vin {
                    ProgressView().tint(.white)
                }
                Image(systemName: "plus")
                Text("Add a vehicle")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canAdd ? Color.appAccent : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!viewModel.canAdd)
    }

    private var yearRange: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(stride(from: currentYear + 1, through: 1980, by: -1))
    }
}

// MARK: - Form Row Style

private struct FormRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(minHeight: 50)
            .background(Color.appSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func formRowStyle() -> some View {
        modifier(FormRowStyle())
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, ChatSession.self, ChatMessage.self], inMemory: true)
}
