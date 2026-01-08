import Foundation

@MainActor
final class TradesViewModel: ObservableObject {
    @Published var accounts: [TradingAccount] = []
    @Published var selectedAccountId: UUID?

    @Published var trades: [Trade] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    // Filters
    @Published var from: Date?
    @Published var to: Date?
    @Published var symbol: String = ""
    @Published var outcome: TradeOutcomeFilter?
    @Published var limit: Int = 100

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
            await loadTrades()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load trades."
        }
    }

    func loadTrades() async {
        guard let accountId = selectedAccountId else {
            trades = []
            return
        }
        errorMessage = nil
        do {
            trades = try await env.api.listTrades(
                accountId: accountId,
                from: from,
                to: to,
                symbol: symbol,
                outcome: outcome,
                limit: limit
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load trades."
        }
    }
}


