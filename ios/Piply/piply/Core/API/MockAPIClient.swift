import Foundation

actor MockAPIClient: APIClient {
    struct Flags: Sendable {
        var forceInvalidAccountCredentials = false
        var forceSyncFailure = false
    }

    private var session: Session?
    private var subscription: SubscriptionInfo = SubscriptionInfo(
        plan: .free,
        status: .active,
        limits: SubscriptionLimits(maxAccounts: 1, manualSyncPerDay: 3, schedulerIntervalMinutes: 360)
    )

    private var flags = Flags()
    private var accounts: [TradingAccount] = []
    private var tradesByAccount: [UUID: [TradeDetail]] = [:]
    private var annotations: [UUID: TradeAnnotation] = [:] // tradeId -> annotation
    private var manualSyncCountToday = 0
    private var manualSyncWindowStart = Calendar.current.startOfDay(for: Date())

    // MARK: - Helpers

    func setFlags(_ newFlags: Flags) async {
        self.flags = newFlags
    }

    func getFlags() async -> Flags {
        flags
    }

    func setPlan(_ plan: Plan) async {
        switch plan {
        case .free:
            subscription.plan = .free
            subscription.limits = SubscriptionLimits(maxAccounts: 1, manualSyncPerDay: 3, schedulerIntervalMinutes: 360)
        case .pro:
            subscription.plan = .pro
            subscription.limits = SubscriptionLimits(maxAccounts: 5, manualSyncPerDay: 30, schedulerIntervalMinutes: 30)
        }
    }

    private func requireSession() throws -> Session {
        guard let s = session else { throw APIError.notAuthenticated }
        return s
    }

    private func simulateLatency(_ ms: UInt64 = 250) async {
        try? await Task.sleep(nanoseconds: ms * 1_000_000)
    }

    private func resetWindowIfNeeded(now: Date) {
        let start = Calendar.current.startOfDay(for: now)
        if start != manualSyncWindowStart {
            manualSyncWindowStart = start
            manualSyncCountToday = 0
        }
    }

    private func seedTradesIfNeeded(for accountId: UUID) {
        if tradesByAccount[accountId] != nil { return }

        let now = Date()
        let sample: [TradeDetail] = [
            TradeDetail(
                id: UUID(),
                tradingAccountId: accountId,
                symbol: "XAUUSD",
                side: .buy,
                openTime: now.addingTimeInterval(-60 * 60 * 24 * 10),
                closeTime: now.addingTimeInterval(-60 * 60 * 24 * 10 + 60 * 22),
                openPrice: 2050.10,
                closePrice: 2056.40,
                volume: 0.10,
                sl: nil,
                tp: nil,
                commission: -0.5,
                swap: 0,
                profit: 62.3
            ),
            TradeDetail(
                id: UUID(),
                tradingAccountId: accountId,
                symbol: "EURUSD",
                side: .sell,
                openTime: now.addingTimeInterval(-60 * 60 * 24 * 7),
                closeTime: now.addingTimeInterval(-60 * 60 * 24 * 7 + 60 * 45),
                openPrice: 1.0912,
                closePrice: 1.0940,
                volume: 0.20,
                sl: 1.0960,
                tp: 1.0880,
                commission: -0.8,
                swap: -0.1,
                profit: -56.0
            ),
            TradeDetail(
                id: UUID(),
                tradingAccountId: accountId,
                symbol: "US30",
                side: .buy,
                openTime: now.addingTimeInterval(-60 * 60 * 24 * 2),
                closeTime: now.addingTimeInterval(-60 * 60 * 24 * 2 + 60 * 12),
                openPrice: 38250,
                closePrice: 38310,
                volume: 0.05,
                sl: nil,
                tp: nil,
                commission: 0,
                swap: 0,
                profit: 30.0
            )
        ]

        tradesByAccount[accountId] = sample
        for t in sample {
            annotations[t.id] = TradeAnnotation(noteText: "", tags: [])
        }
    }

    // MARK: - Auth

    func signup(email: String, password: String) async throws -> Session {
        await simulateLatency()
        guard email.contains("@") else { throw APIError.validation(message: "Please enter a valid email.") }
        guard password.count >= 6 else { throw APIError.validation(message: "Password must be at least 6 characters.") }
        let s = Session(token: UUID().uuidString, email: email)
        session = s
        return s
    }

    func login(email: String, password: String) async throws -> Session {
        await simulateLatency()
        guard email.contains("@") else { throw APIError.validation(message: "Please enter a valid email.") }
        guard password.count >= 1 else { throw APIError.validation(message: "Please enter your password.") }
        let s = Session(token: UUID().uuidString, email: email)
        session = s
        return s
    }

    func logout() async {
        session = nil
    }

    // MARK: - Subscription

    func getSubscription() async throws -> SubscriptionInfo {
        _ = try requireSession()
        await simulateLatency()
        return subscription
    }

    // MARK: - Accounts

    func listTradingAccounts() async throws -> [TradingAccount] {
        _ = try requireSession()
        await simulateLatency()
        return accounts.sorted { $0.createdAt > $1.createdAt }
    }

    func createTradingAccount(broker: String, server: String, accountId: String, readOnlyPassword: String) async throws -> TradingAccount {
        _ = try requireSession()
        await simulateLatency()

        let brokerT = broker.trimmingCharacters(in: .whitespacesAndNewlines)
        let serverT = server.trimmingCharacters(in: .whitespacesAndNewlines)
        let accountT = accountId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !brokerT.isEmpty else { throw APIError.validation(message: "Broker is required.") }
        guard !serverT.isEmpty else { throw APIError.validation(message: "Server is required.") }
        guard !accountT.isEmpty else { throw APIError.validation(message: "Account ID is required.") }
        guard readOnlyPassword.count >= 4 else { throw APIError.validation(message: "Password is too short.") }

        if subscription.plan == .free && accounts.count >= subscription.limits.maxAccounts {
            throw APIError.planLimitReached(message: "Free plan allows only \(subscription.limits.maxAccounts) account. Upgrade to Pro to add more.")
        }

        if flags.forceInvalidAccountCredentials {
            throw APIError.invalidCredentials
        }

        if accounts.contains(where: { $0.broker.caseInsensitiveCompare(brokerT) == .orderedSame && $0.server.caseInsensitiveCompare(serverT) == .orderedSame && $0.accountId == accountT }) {
            throw APIError.validation(message: "This account is already connected.")
        }

        let now = Date()
        let newAccount = TradingAccount(
            id: UUID(),
            broker: brokerT,
            server: serverT,
            accountId: accountT,
            status: .pending,
            lastAttemptedSyncAt: nil,
            lastSuccessfulSyncAt: nil,
            lastErrorMessage: nil,
            createdAt: now,
            updatedAt: now
        )
        accounts.append(newAccount)
        seedTradesIfNeeded(for: newAccount.id)
        return newAccount
    }

    func deleteTradingAccount(id: UUID) async throws {
        _ = try requireSession()
        await simulateLatency()
        accounts.removeAll { $0.id == id }
        tradesByAccount[id] = nil
    }

    func triggerSync(tradingAccountId: UUID) async throws -> String {
        _ = try requireSession()
        await simulateLatency(150)

        resetWindowIfNeeded(now: Date())

        // quota enforcement
        if manualSyncCountToday >= subscription.limits.manualSyncPerDay {
            throw APIError.rateLimited(message: "You’ve reached your manual sync limit for today.")
        }
        manualSyncCountToday += 1

        guard let idx = accounts.firstIndex(where: { $0.id == tradingAccountId }) else { throw APIError.notFound }

        let jobId = "job_" + UUID().uuidString.prefix(8)
        let now = Date()
        accounts[idx].status = .syncing
        accounts[idx].lastAttemptedSyncAt = now
        accounts[idx].updatedAt = now

        // simulate background completion (still within actor)
        try? await Task.sleep(nanoseconds: 700_000_000)
        let finish = Date()
        if flags.forceSyncFailure {
            accounts[idx].status = .failed
            accounts[idx].lastErrorMessage = "Sync failed. Please check your account info and try again."
            accounts[idx].updatedAt = finish
        } else {
            accounts[idx].status = .synced
            accounts[idx].lastSuccessfulSyncAt = finish
            accounts[idx].lastErrorMessage = nil
            accounts[idx].updatedAt = finish
        }

        return String(jobId)
    }

    // MARK: - Trades

    func listTrades(accountId: UUID, from: Date?, to: Date?, symbol: String?, outcome: TradeOutcomeFilter?, limit: Int?) async throws -> [Trade] {
        _ = try requireSession()
        await simulateLatency()
        seedTradesIfNeeded(for: accountId)

        let all = tradesByAccount[accountId] ?? []
        var filtered = all

        if let from {
            filtered = filtered.filter { $0.closeTime ?? $0.openTime >= from }
        }
        if let to {
            filtered = filtered.filter { $0.closeTime ?? $0.openTime <= to }
        }
        if let symbol, !symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let s = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            filtered = filtered.filter { $0.symbol.uppercased().contains(s) }
        }
        if let outcome {
            filtered = filtered.filter {
                let p = $0.profit ?? 0
                switch outcome {
                case .win: return p > 0
                case .loss: return p < 0
                case .breakeven: return p == 0
                }
            }
        }

        filtered.sort { ($0.closeTime ?? $0.openTime) > ($1.closeTime ?? $1.openTime) }

        let capped = Array(filtered.prefix(limit ?? 100))
        return capped.map {
            Trade(
                id: $0.id,
                tradingAccountId: $0.tradingAccountId,
                symbol: $0.symbol,
                side: $0.side,
                openTime: $0.openTime,
                closeTime: $0.closeTime,
                profit: $0.profit
            )
        }
    }

    func getTradeDetail(tradeId: UUID) async throws -> TradeDetail {
        _ = try requireSession()
        await simulateLatency()

        for (_, list) in tradesByAccount {
            if let t = list.first(where: { $0.id == tradeId }) {
                return t
            }
        }
        throw APIError.notFound
    }

    func getTradeAnnotation(tradeId: UUID) async throws -> TradeAnnotation {
        _ = try requireSession()
        await simulateLatency(100)
        return annotations[tradeId] ?? TradeAnnotation(noteText: "", tags: [])
    }

    func updateTradeAnnotation(tradeId: UUID, noteText: String, tags: [String]) async throws -> TradeAnnotation {
        _ = try requireSession()
        await simulateLatency(150)
        let cleanedTags = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let a = TradeAnnotation(noteText: noteText, tags: Array(Set(cleanedTags)).sorted())
        annotations[tradeId] = a
        return a
    }

    // MARK: - Analytics

    func getAnalyticsSummary(accountId: UUID, from: Date?, to: Date?) async throws -> AnalyticsSummary {
        _ = try requireSession()
        await simulateLatency()

        let trades = try await listTrades(accountId: accountId, from: from, to: to, symbol: nil, outcome: nil, limit: 10_000)
        let profits = trades.compactMap { $0.profit }
        let pnl = profits.reduce(Decimal(0), +)
        let wins = profits.filter { $0 > 0 }.count
        let count = trades.count
        let winRate = count == 0 ? 0 : Double(wins) / Double(count)

        // MVP: simple drawdown placeholder (negative cumulative min as absolute)
        var equity = Decimal(0)
        var peak = Decimal(0)
        var maxDD = Decimal(0)
        for p in profits {
            equity += p
            if equity > peak { peak = equity }
            let dd = peak - equity
            if dd > maxDD { maxDD = dd }
        }

        return AnalyticsSummary(pnlTotal: pnl, winRate: winRate, maxDrawdown: maxDD, tradeCount: count)
    }

    func getPnlSeries(accountId: UUID, from: Date?, to: Date?, bucket: PnlSeries.Bucket) async throws -> PnlSeries {
        _ = try requireSession()
        await simulateLatency()

        // Simple mocked series
        let points: [PnlPoint] = [
            PnlPoint(dayISO: "2026-01-01", pnl: 12),
            PnlPoint(dayISO: "2026-01-02", pnl: -8),
            PnlPoint(dayISO: "2026-01-03", pnl: 20),
            PnlPoint(dayISO: "2026-01-04", pnl: 5)
        ]
        return PnlSeries(bucket: bucket, points: points)
    }
}


