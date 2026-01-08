import Foundation

@MainActor
final class PricingViewModel: ObservableObject {
    @Published var subscription: SubscriptionInfo?
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            subscription = try await env.api.getSubscription()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load subscription."
        }
    }

    func setPlan(_ plan: Plan) async {
        // UI-first: only Mock supports plan switching locally.
        if let mock = env.api as? MockAPIClient {
            await mock.setPlan(plan)
            await refresh()
        } else {
            errorMessage = "Checkout is not configured yet."
        }
    }
}


