import SwiftUI

struct SettingsView: View {
    let env: AppEnvironment
    @State private var isPro = false
    @State private var forceInvalidCreds = false
    @State private var forceSyncFailure = false
    @State private var subscription: SubscriptionInfo?
    @State private var subscriptionError: String?

    var body: some View {
        List {
            Section("Account") {
                Text("Logged in as")
                    .foregroundStyle(DS.ColorToken.textSecondary)
                Text(env.session?.email ?? "—")
                    .foregroundStyle(DS.ColorToken.textPrimary)
            }

            Section("Subscription") {
                if let subscription {
                    HStack {
                        Text("Plan")
                        Spacer()
                        Text(subscription.plan.rawValue.uppercased())
                            .font(.subheadline.weight(.semibold))
                    }
                    HStack {
                        Text("Max accounts")
                        Spacer()
                        Text("\(subscription.limits.maxAccounts)")
                    }
                    HStack {
                        Text("Manual sync/day")
                        Spacer()
                        Text("\(subscription.limits.manualSyncPerDay)")
                    }
                    HStack {
                        Text("Scheduler interval")
                        Spacer()
                        Text("\(subscription.limits.schedulerIntervalMinutes) min")
                    }
                } else if let subscriptionError {
                    Text(subscriptionError)
                        .foregroundStyle(DS.ColorToken.danger)
                } else {
                    ProgressView()
                }

                NavigationLink("View pricing") {
                    PricingView(env: env)
                }
            }

            Section("Debug (Mock only)") {
                Toggle("Pro plan", isOn: $isPro)
                    .onChange(of: isPro) { _, newValue in
                        Task {
                            guard let mock = env.api as? MockAPIClient else { return }
                            await mock.setPlan(newValue ? .pro : .free)
                            await loadSubscription()
                        }
                    }

                Toggle("Force invalid account credentials", isOn: $forceInvalidCreds)
                    .onChange(of: forceInvalidCreds) { _, _ in
                        Task { await applyFlags() }
                    }

                Toggle("Force sync failure", isOn: $forceSyncFailure)
                    .onChange(of: forceSyncFailure) { _, _ in
                        Task { await applyFlags() }
                    }
            }

            Section {
                Button(role: .destructive) {
                    env.clearSession()
                } label: {
                    Text("Logout")
                }
            }
        }
        .navigationTitle("Settings")
        .task {
            await loadDebugState()
            await loadSubscription()
        }
        .background(DS.ColorToken.background)
    }

    private func loadDebugState() async {
        guard let mock = env.api as? MockAPIClient else { return }
        let sub = try? await mock.getSubscription()
        isPro = sub?.plan == .pro

        let flags = await mock.getFlags()
        forceInvalidCreds = flags.forceInvalidAccountCredentials
        forceSyncFailure = flags.forceSyncFailure
    }

    private func loadSubscription() async {
        subscriptionError = nil
        do {
            subscription = try await env.api.getSubscription()
        } catch {
            subscriptionError = (error as? LocalizedError)?.errorDescription ?? "Failed to load subscription."
        }
    }

    private func applyFlags() async {
        guard let mock = env.api as? MockAPIClient else { return }
        await mock.setFlags(.init(forceInvalidAccountCredentials: forceInvalidCreds, forceSyncFailure: forceSyncFailure))
    }
}


