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
    
    // Initialize with mock data for development
    init() {
        // Auto-login for easier testing
        session = Session(token: "mock_token_\(UUID().uuidString)", email: "demo@example.com")
        
        // Create mock accounts
        let now = Date()
        let account1 = TradingAccount(
            id: UUID(),
            broker: "IC Markets",
            server: "ICMarkets-Demo",
            accountId: "12345678",
            status: .synced,
            lastAttemptedSyncAt: now.addingTimeInterval(-3600),
            lastSuccessfulSyncAt: now.addingTimeInterval(-3600),
            lastErrorMessage: nil,
            createdAt: now.addingTimeInterval(-86400 * 30),
            updatedAt: now.addingTimeInterval(-3600)
        )
        
        let account2 = TradingAccount(
            id: UUID(),
            broker: "FXTM",
            server: "FXTM-Demo",
            accountId: "87654321",
            status: .synced,
            lastAttemptedSyncAt: now.addingTimeInterval(-7200),
            lastSuccessfulSyncAt: now.addingTimeInterval(-7200),
            lastErrorMessage: nil,
            createdAt: now.addingTimeInterval(-86400 * 15),
            updatedAt: now.addingTimeInterval(-7200)
        )
        
        accounts = [account1, account2]
        
        // Seed trades for accounts
        seedTradesForAccount(account1.id, accountName: "IC Markets")
        seedTradesForAccount(account2.id, accountName: "FXTM")
    }
    
    private func seedTradesForAccount(_ accountId: UUID, accountName: String) {
        let now = Date()
        let calendar = Calendar.current
        
        // Generate trades for the last 30 days
        var trades: [TradeDetail] = []
        let symbols = ["XAUUSD", "EURUSD", "GBPUSD", "USDJPY", "US30", "BTCUSD", "ETHUSD"]
        let sides: [TradeSide] = [.buy, .sell]
        
        for dayOffset in 0..<30 {
            let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let tradesPerDay = Int.random(in: 1...5)
            
            for tradeIndex in 0..<tradesPerDay {
                let symbol = symbols.randomElement()!
                let side = sides.randomElement()!
                let openTime = calendar.date(byAdding: .hour, value: tradeIndex * 2, to: dayDate)!
                let closeTime = calendar.date(byAdding: .minute, value: Int.random(in: 15...120), to: openTime)!
                
                // Generate realistic profit/loss
                let basePriceRaw: Decimal = symbol.contains("USD") ? 1.0 : (symbol.contains("XAU") ? 2050 : 38000)
                let priceChangePercent = Double.random(in: -2.0...2.0)
                let volumeRaw = Double.random(in: 0.01...0.5)
                let profitValue = Double.random(in: -100...200)
                
                // Round values appropriately
                let basePrice = roundPrice(basePriceRaw, forSymbol: symbol)
                let priceChange = Decimal(priceChangePercent / 100.0)
                let closePriceRaw = basePrice * (Decimal(1.0) + priceChange)
                let closePrice = roundPrice(closePriceRaw, forSymbol: symbol)
                let volume = roundDecimalFromDouble(volumeRaw, toPlaces: 2)
                let profit = roundDecimalFromDouble(profitValue, toPlaces: 2)
                let sl = roundPrice(side == .buy ? basePrice * Decimal(0.99) : basePrice * Decimal(1.01), forSymbol: symbol)
                let tp = roundPrice(side == .buy ? basePrice * Decimal(1.01) : basePrice * Decimal(0.99), forSymbol: symbol)
                let commission = roundDecimalFromDouble(Double.random(in: -1.0...0), toPlaces: 2)
                let swap = roundDecimalFromDouble(Double.random(in: -0.5...0.5), toPlaces: 2)
                
                let trade = TradeDetail(
                    id: UUID(),
                    tradingAccountId: accountId,
                    symbol: symbol,
                    side: side,
                    openTime: openTime,
                    closeTime: closeTime,
                    openPrice: basePrice,
                    closePrice: closePrice,
                    volume: volume,
                    sl: sl,
                    tp: tp,
                    commission: commission,
                    swap: swap,
                    profit: profit
                )
                trades.append(trade)
                
                // Add some annotations
                if Bool.random() {
                    annotations[trade.id] = TradeAnnotation(
                        noteText: "Good entry point",
                        tags: ["scalping", "trend"]
                    )
                }
            }
        }
        
        tradesByAccount[accountId] = trades.sorted { ($0.closeTime ?? $0.openTime) > ($1.closeTime ?? $1.openTime) }
    }

    // MARK: - Helpers
    
    private func roundDecimal(_ value: Decimal, toPlaces places: Int = 2) -> Decimal {
        var result = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &result, places, .bankers)
        return rounded
    }
    
    private func roundDecimalFromDouble(_ value: Double, toPlaces places: Int = 2) -> Decimal {
        let multiplier = pow(10.0, Double(places))
        let rounded = (value * multiplier).rounded() / multiplier
        return roundDecimal(Decimal(rounded), toPlaces: places)
    }
    
    private func roundPrice(_ value: Decimal, forSymbol symbol: String) -> Decimal {
        // Forex: 5 decimal places, Gold: 2 decimal places, Indices: 2 decimal places
        let places = symbol.contains("XAU") || symbol.contains("US30") ? 2 : 5
        return roundDecimal(value, toPlaces: places)
    }

    func getCurrentSession() async -> Session? {
        return session
    }

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
        seedTradesForAccount(accountId, accountName: "New Account")
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
        let pnlRaw = profits.reduce(Decimal(0), +)
        let pnl = roundDecimal(pnlRaw, toPlaces: 2)
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
        let maxDDRounded = roundDecimal(maxDD, toPlaces: 2)

        return AnalyticsSummary(pnlTotal: pnl, winRate: winRate, maxDrawdown: maxDDRounded, tradeCount: count)
    }

    func getPnlSeries(accountId: UUID, from: Date?, to: Date?, bucket: PnlSeries.Bucket) async throws -> PnlSeries {
        _ = try requireSession()
        await simulateLatency()

        // Generate realistic PnL series from actual trades
        seedTradesIfNeeded(for: accountId)
        let allTrades = tradesByAccount[accountId] ?? []
        
        // Group trades by day
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var dailyPnL: [String: Decimal] = [:]
        
        for trade in allTrades {
            let tradeDate = trade.closeTime ?? trade.openTime
            let dayISO = dateFormatter.string(from: tradeDate)
            let profit = trade.profit ?? 0
            dailyPnL[dayISO, default: 0] += profit
        }
        
        // Convert to PnlPoint array and sort by date, rounding PnL values
        let points = dailyPnL.map { 
            PnlPoint(dayISO: $0.key, pnl: roundDecimal($0.value, toPlaces: 2))
        }
        .sorted { $0.dayISO < $1.dayISO }
        
        // If no trades, return sample data
        if points.isEmpty {
            let calendar = Calendar.current
            let now = Date()
            var samplePoints: [PnlPoint] = []
            
            for dayOffset in 0..<30 {
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
                let dayISO = dateFormatter.string(from: date)
                let pnlRaw = Double.random(in: -50...100)
                let pnl = roundDecimalFromDouble(pnlRaw, toPlaces: 2)
                samplePoints.append(PnlPoint(dayISO: dayISO, pnl: pnl))
            }
            
            return PnlSeries(bucket: bucket, points: samplePoints.reversed())
        }
        
        return PnlSeries(bucket: bucket, points: points)
    }
}


