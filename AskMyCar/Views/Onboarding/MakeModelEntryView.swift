import SwiftUI

struct MakeModelEntryView: View {
    @Bindable var viewModel: OnboardingViewModel

    private var yearRange: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(stride(from: currentYear + 1, through: 1980, by: -1))
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Vehicle Details")
                .font(.title2.bold())

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
                .padding()
                .background(Color.appSecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                TextField("Make (e.g. Toyota)", text: $viewModel.make)
                    .textInputAutocapitalization(.words)
                    .padding()
                    .background(Color.appSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                TextField("Model (e.g. Camry)", text: $viewModel.model)
                    .textInputAutocapitalization(.words)
                    .padding()
                    .background(Color.appSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                TextField("Trim (optional, e.g. XSE)", text: $viewModel.trim)
                    .textInputAutocapitalization(.characters)
                    .padding()
                    .background(Color.appSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                viewModel.currentStep = .confirmation
            } label: {
                Text("Add Vehicle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canAddVehicle ? Color.appAccent : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.canAddVehicle)
        }
        .padding()
    }
}

#Preview {
    MakeModelEntryView(viewModel: OnboardingViewModel())
}
