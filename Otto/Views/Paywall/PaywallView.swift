import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedPlan: PlanType = .yearly

    private var manager: SubscriptionManager { appState.subscriptionManager }

    enum PlanType { case monthly, yearly }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero
            VStack(spacing: 12) {
                Image("AppIcon-Display")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                Text("Otto Premium")
                    .font(.title.bold())

                Text("Start your 7-day free trial")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 32)

            // Feature bullets
            VStack(alignment: .leading, spacing: 14) {
                featureRow(icon: "bubble.left.and.bubble.right.fill", text: "Unlimited AI chat")
                featureRow(icon: "wrench.and.screwdriver.fill", text: "Maintenance tracking")
                featureRow(icon: "exclamationmark.triangle.fill", text: "Recall alerts")
                featureRow(icon: "car.2.fill", text: "Multiple vehicles")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)

            // Plan picker
            VStack(spacing: 12) {
                planOption(
                    type: .yearly,
                    title: "Yearly",
                    price: manager.yearlyProduct?.displayPrice ?? "$29.99",
                    detail: "/year",
                    badge: "Save 50%"
                )
                planOption(
                    type: .monthly,
                    title: "Monthly",
                    price: manager.monthlyProduct?.displayPrice ?? "$4.99",
                    detail: "/month",
                    badge: nil
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Trial note
            trialNote
                .padding(.bottom, 24)

            // CTA
            Button {
                Task { await purchaseSelected() }
            } label: {
                Group {
                    if manager.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Start Free Trial")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.appAccent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(manager.isPurchasing)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // Restore
            Button("Restore Purchases") {
                Task { await manager.restorePurchases() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

            // Error
            if let error = manager.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }

            Spacer()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task {
            await manager.fetchProducts()
        }
    }

    // MARK: - Subviews

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.appAccent)
                .frame(width: 24)
            Text(text)
                .font(.body)
        }
    }

    private func planOption(type: PlanType, title: String, price: String, detail: String, badge: String?) -> some View {
        let isSelected = selectedPlan == type

        return Button { selectedPlan = type } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.appAccent : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title).font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.appAccent)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                Text("\(price)\(detail)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color.appSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.appAccent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var trialNote: some View {
        let price: String
        let period: String
        if selectedPlan == .yearly {
            price = manager.yearlyProduct?.displayPrice ?? "$29.99"
            period = "year"
        } else {
            price = manager.monthlyProduct?.displayPrice ?? "$4.99"
            period = "month"
        }
        return Text("Try free for 7 days, then \(price)/\(period). Cancel anytime.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
    }

    // MARK: - Actions

    private func purchaseSelected() async {
        let product: Product?
        switch selectedPlan {
        case .yearly:
            product = manager.yearlyProduct
        case .monthly:
            product = manager.monthlyProduct
        }
        guard let product else {
            manager.purchaseError = "Products not available. Please try again."
            await manager.fetchProducts()
            return
        }
        await manager.purchase(product)
    }
}

#Preview {
    PaywallView()
        .environment(AppState())
}
