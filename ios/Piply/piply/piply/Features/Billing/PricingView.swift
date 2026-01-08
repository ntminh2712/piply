import SwiftUI

struct PricingView: View {
    let env: AppEnvironment
    @StateObject private var vm: PricingViewModel

    init(env: AppEnvironment) {
        self.env = env
        _vm = StateObject(wrappedValue: PricingViewModel(env: env))
    }

    var body: some View {
        List {
            if let error = vm.errorMessage {
                Section { Text(error).foregroundStyle(.red) }
            }

            Section {
                Text("Choose the plan that matches your needs. All limits are enforced server-side once backend is connected.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Plans") {
                planCard(
                    title: "Free",
                    subtitle: "Try Piply with basic limits",
                    plan: .free,
                    limits: SubscriptionLimits(maxAccounts: 1, manualSyncPerDay: 3, schedulerIntervalMinutes: 360)
                )
                planCard(
                    title: "Pro",
                    subtitle: "More accounts, faster sync, higher quotas",
                    plan: .pro,
                    limits: SubscriptionLimits(maxAccounts: 5, manualSyncPerDay: 30, schedulerIntervalMinutes: 30)
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Pricing")
        .task { await vm.refresh() }
        .refreshable { await vm.refresh() }
        .background(DS.ColorToken.background)
    }

    private func planCard(title: String, subtitle: String, plan: Plan, limits: SubscriptionLimits) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if vm.subscription?.plan == plan {
                    Text("Current")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DS.ColorToken.accent.opacity(0.15))
                        .foregroundStyle(DS.ColorToken.accent)
                        .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("• Max accounts: \(limits.maxAccounts)")
                Text("• Manual sync/day: \(limits.manualSyncPerDay)")
                Text("• Scheduler interval: \(limits.schedulerIntervalMinutes) min")
            }
            .font(.subheadline)

            PrimaryButton(title: plan == .pro ? "Upgrade to Pro" : "Switch to Free") {
                Task { await vm.setPlan(plan) }
            }
        }
        .card(elevated: true)
    }
}


