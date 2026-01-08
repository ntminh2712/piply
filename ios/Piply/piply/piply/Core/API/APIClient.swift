import Foundation

protocol APIClient: Sendable {
    // Auth (stub for UI-first)
    func signup(email: String, password: String) async throws -> Session
    func login(email: String, password: String) async throws -> Session
    func logout() async

    // Subscription
    func getSubscription() async throws -> SubscriptionInfo

    // Trading accounts
    func listTradingAccounts() async throws -> [TradingAccount]
    func createTradingAccount(broker: String, server: String, accountId: String, readOnlyPassword: String) async throws -> TradingAccount
    func deleteTradingAccount(id: UUID) async throws
    func triggerSync(tradingAccountId: UUID) async throws -> String // jobId

    // Trades
    func listTrades(
        accountId: UUID,
        from: Date?,
        to: Date?,
        symbol: String?,
        outcome: TradeOutcomeFilter?,
        limit: Int?
    ) async throws -> [Trade]
    func getTradeDetail(tradeId: UUID) async throws -> TradeDetail
    func getTradeAnnotation(tradeId: UUID) async throws -> TradeAnnotation
    func updateTradeAnnotation(tradeId: UUID, noteText: String, tags: [String]) async throws -> TradeAnnotation

    // Analytics
    func getAnalyticsSummary(accountId: UUID, from: Date?, to: Date?) async throws -> AnalyticsSummary
    func getPnlSeries(accountId: UUID, from: Date?, to: Date?, bucket: PnlSeries.Bucket) async throws -> PnlSeries
    func getEquitySeries(accountId: UUID, from: Date?, to: Date?) async throws -> EquitySeries
    func getOpenTrades(accountId: UUID) async throws -> [Trade]
    func getInsights(accountId: UUID) async throws -> [Insight]
}


