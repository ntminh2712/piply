import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var accounts: [TradingAccount] = []
    @Published var selectedAccountId: UUID?

    @Published var summary: AnalyticsSummary?
    @Published var series: PnlSeries?
    @Published var equitySeries: EquitySeries?
    @Published var recentTrades: [Trade] = []
    @Published var openTrades: [Trade] = []
    @Published var insights: [Insight] = []

    @Published var errorMessage: String?
    @Published var isLoading = false

    // UI hook (for future): switch tab programmatically
    @Published var requestGoToAccounts = false

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            accounts = try await env.api.listTradingAccounts()
            if selectedAccountId == nil {
                selectedAccountId = accounts.first?.id
            }
            await loadAnalytics()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load dashboard."
        }
    }

    func loadAnalytics() async {
        guard let accountId = selectedAccountId else {
            summary = nil
            series = nil
            equitySeries = nil
            recentTrades = []
            openTrades = []
            insights = []
            return
        }

        do {
            async let s = env.api.getAnalyticsSummary(accountId: accountId, from: nil, to: nil)
            async let p = env.api.getPnlSeries(accountId: accountId, from: nil, to: nil, bucket: .daily)
            async let e = env.api.getEquitySeries(accountId: accountId, from: nil, to: nil)
            async let r = env.api.listTrades(accountId: accountId, from: nil, to: nil, symbol: nil, outcome: nil, limit: 10)
            async let o = env.api.getOpenTrades(accountId: accountId)
            async let i = env.api.getInsights(accountId: accountId)
            
            summary = try await s
            series = try await p
            equitySeries = try await e
            recentTrades = try await r
            openTrades = try await o
            insights = try await i
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load analytics."
        }
    }
}


