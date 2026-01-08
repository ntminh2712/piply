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

        let allTrades = try await listTrades(accountId: accountId, from: from, to: to, symbol: nil, outcome: nil, limit: 10_000)
        let closedTrades = allTrades.filter { !$0.isOpen }
        let profits = closedTrades.compactMap { $0.profit }
        let pnlRaw = profits.reduce(Decimal(0), +)
        let pnl = roundDecimal(pnlRaw, toPlaces: 2)
        let wins = profits.filter { $0 > 0 }.count
        let losses = profits.filter { $0 < 0 }
        let count = closedTrades.count
        let winRate = count == 0 ? 0 : Double(wins) / Double(count)

        // Calculate equity (starting from 10000, add P/L)
        let startingEquity = Decimal(10000)
        let equity = roundDecimal(startingEquity + pnl, toPlaces: 2)
        
        // Daily P/L (today's trades)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayTrades = closedTrades.filter { 
            guard let closeTime = $0.closeTime else { return false }
            return calendar.isDate(closeTime, inSameDayAs: Date())
        }
        let dailyPnL = roundDecimal(todayTrades.compactMap { $0.profit }.reduce(Decimal(0), +), toPlaces: 2)
        
        // Profit factor
        let grossProfit = profits.filter { $0 > 0 }.reduce(Decimal(0), +)
        let grossLossRaw = profits.filter { $0 < 0 }.reduce(Decimal(0), +)
        // Get absolute value (Decimal doesn't conform to Comparable for abs())
        let grossLoss = grossLossRaw < 0 ? -grossLossRaw : grossLossRaw
        let profitFactor = grossLoss > 0 ? (grossProfit as NSDecimalNumber).doubleValue / (grossLoss as NSDecimalNumber).doubleValue : nil
        
        // Avg win/loss
        let avgWin = wins > 0 ? roundDecimal(grossProfit / Decimal(wins), toPlaces: 2) : nil
        let avgLoss = losses.count > 0 ? roundDecimal(grossLoss / Decimal(losses.count), toPlaces: 2) : nil
        
        // Drawdown calculation
        var runningEquity = startingEquity
        var peak = startingEquity
        var maxDD = Decimal(0)
        for p in profits {
            runningEquity += p
            if runningEquity > peak { peak = runningEquity }
            let dd = peak - runningEquity
            if dd > maxDD { maxDD = dd }
        }
        let maxDDRounded = roundDecimal(maxDD, toPlaces: 2)
        
        // Current risk (simplified: based on open trades)
        let openTrades = try await getOpenTrades(accountId: accountId)
        let openRisk = openTrades.count > 0 ? Decimal(openTrades.count * 2) : Decimal(0) // 2% per open trade
        let currentRisk = roundDecimal(openRisk, toPlaces: 1)
        
        // Losing streak
        var currentStreak = 0
        var maxStreak = 0
        var tempStreak = 0
        for profit in profits.reversed() {
            if profit < 0 {
                tempStreak += 1
                maxStreak = max(maxStreak, tempStreak)
                if tempStreak == 1 { currentStreak = tempStreak }
            } else {
                if tempStreak > 0 && currentStreak == 0 { currentStreak = tempStreak }
                tempStreak = 0
            }
        }
        if tempStreak > 0 && currentStreak == 0 { currentStreak = tempStreak }
        
        // Overtrade warning (if more than 10 trades today)
        let overtradeWarning = todayTrades.count > 10
        
        // Expectancy = (Win Rate × Avg Win) - (Loss Rate × Avg Loss)
        let lossRate = 1.0 - winRate
        let winRateDecimal = Decimal(winRate)
        let lossRateDecimal = Decimal(lossRate)
        let avgWinValue = avgWin ?? 0
        let avgLossRaw = avgLoss ?? 0
        // Get absolute value of avgLoss (Decimal doesn't conform to Comparable for abs())
        let avgLossValue = avgLossRaw < 0 ? -avgLossRaw : avgLossRaw
        let expectancy = (winRateDecimal * avgWinValue) - (lossRateDecimal * avgLossValue)
        let expectancyDecimal = roundDecimal(expectancy, toPlaces: 2)
        
        // Avg R:R (simplified: avgWin / avgLoss)
        let avgWinDouble = (avgWin ?? 0) as NSDecimalNumber
        let avgLossDouble = (avgLoss ?? 0) as NSDecimalNumber
        let avgWinAbs = abs(avgWinDouble.doubleValue)
        let avgLossAbs = abs(avgLossDouble.doubleValue)
        let avgRR = avgLossAbs > 0 ? avgWinAbs / avgLossAbs : nil

        return AnalyticsSummary(
            pnlTotal: pnl,
            winRate: winRate,
            maxDrawdown: maxDDRounded,
            tradeCount: count,
            equity: equity,
            dailyPnL: dailyPnL,
            profitFactor: profitFactor,
            avgWin: avgWin,
            avgLoss: avgLoss,
            expectancy: expectancyDecimal,
            avgRR: avgRR,
            currentRisk: currentRisk,
            losingStreak: currentStreak > 0 ? currentStreak : nil,
            maxLosingStreak: maxStreak > 0 ? maxStreak : nil,
            overtradeWarning: overtradeWarning ? true : nil
        )
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
    
    func getEquitySeries(accountId: UUID, from: Date?, to: Date?) async throws -> EquitySeries {
        _ = try requireSession()
        await simulateLatency()
        
        seedTradesIfNeeded(for: accountId)
        let allTrades = tradesByAccount[accountId] ?? []
        let closedTrades = allTrades.filter { $0.closeTime != nil }
            .sorted { ($0.closeTime ?? $0.openTime) < ($1.closeTime ?? $1.openTime) }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startingEquity = Decimal(10000)
        var runningEquity = startingEquity
        var dailyEquity: [String: Decimal] = [:]
        
        // Initialize with starting equity
        if let firstTrade = closedTrades.first {
            let firstDate = firstTrade.openTime
            let firstDayISO = dateFormatter.string(from: firstDate)
            dailyEquity[firstDayISO] = startingEquity
        }
        
        // Build equity curve from trades
        for trade in closedTrades {
            guard let closeTime = trade.closeTime else { continue }
            let dayISO = dateFormatter.string(from: closeTime)
            let profit = trade.profit ?? 0
            runningEquity += profit
            dailyEquity[dayISO] = runningEquity
        }
        
        // Convert to EquityPoint array
        let points = dailyEquity.map { EquityPoint(dayISO: $0.key, equity: roundDecimal($0.value, toPlaces: 2)) }
            .sorted { $0.dayISO < $1.dayISO }
        
        // If no trades, return sample data
        if points.isEmpty {
            let calendar = Calendar.current
            let now = Date()
            var samplePoints: [EquityPoint] = []
            var sampleEquity = startingEquity
            
            for dayOffset in 0..<30 {
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
                let dayISO = dateFormatter.string(from: date)
                let change = Decimal(Double.random(in: -50...100))
                sampleEquity += change
                samplePoints.append(EquityPoint(dayISO: dayISO, equity: roundDecimal(sampleEquity, toPlaces: 2)))
            }
            
            return EquitySeries(points: samplePoints.reversed())
        }
        
        return EquitySeries(points: points)
    }
    
    func getOpenTrades(accountId: UUID) async throws -> [Trade] {
        _ = try requireSession()
        await simulateLatency()
        
        seedTradesIfNeeded(for: accountId)
        let allTrades = tradesByAccount[accountId] ?? []
        let openTrades = allTrades.filter { $0.closeTime == nil }
        
        // Generate some mock open trades
        if openTrades.isEmpty {
            let now = Date()
            let symbols = ["XAUUSD", "EURUSD", "GBPUSD"]
            var mockOpenTrades: [TradeDetail] = []
            
            for i in 0..<Int.random(in: 0...3) {
                let symbol = symbols.randomElement()!
                let trade = TradeDetail(
                    id: UUID(),
                    tradingAccountId: accountId,
                    symbol: symbol,
                    side: i % 2 == 0 ? .buy : .sell,
                    openTime: now.addingTimeInterval(-Double(i) * 3600),
                    closeTime: nil,
                    openPrice: symbol.contains("USD") ? Decimal(1.0) : Decimal(2050),
                    closePrice: nil,
                    volume: roundDecimalFromDouble(Double.random(in: 0.01...0.5), toPlaces: 2),
                    sl: nil,
                    tp: nil,
                    commission: nil,
                    swap: nil,
                    profit: roundDecimalFromDouble(Double.random(in: -20...30), toPlaces: 2)
                )
                mockOpenTrades.append(trade)
            }
            
            return mockOpenTrades.map {
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
        
        return openTrades.map {
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
    
    func getInsights(accountId: UUID) async throws -> [Insight] {
        _ = try requireSession()
        await simulateLatency()
        
        seedTradesIfNeeded(for: accountId)
        let allTrades = tradesByAccount[accountId] ?? []
        var insights: [Insight] = []
        
        // Time-based insight
        let calendar = Calendar.current
        let hourCounts = Dictionary(grouping: allTrades, by: { calendar.component(.hour, from: $0.openTime) })
        if let bestHour = hourCounts.max(by: { $0.value.count < $1.value.count }) {
            insights.append(Insight(
                id: UUID(),
                type: .timeBased,
                title: "Best Trading Hour",
                message: "Most trades executed at \(bestHour.key):00 with \(bestHour.value.count) trades",
                severity: .info
            ))
        }
        
        // Pair-based insight
        let symbolCounts = Dictionary(grouping: allTrades, by: { $0.symbol })
        if let bestSymbol = symbolCounts.max(by: { $0.value.count < $1.value.count }) {
            let symbolProfit = bestSymbol.value.compactMap { $0.profit }.reduce(Decimal(0), +)
            insights.append(Insight(
                id: UUID(),
                type: .pairBased,
                title: "Top Trading Pair",
                message: "\(bestSymbol.key) has \(bestSymbol.value.count) trades with \(formatDecimal(symbolProfit)) P/L",
                severity: symbolProfit >= 0 ? .info : .warning
            ))
        }
        
        // Behavior insight
        let recentTrades = allTrades.suffix(10)
        let recentWins = recentTrades.filter { ($0.profit ?? 0) > 0 }.count
        if recentWins < 3 && recentTrades.count >= 5 {
            insights.append(Insight(
                id: UUID(),
                type: .behavior,
                title: "Recent Performance",
                message: "Only \(recentWins) wins in last 10 trades. Consider reviewing strategy.",
                severity: .warning
            ))
        }
        
        return insights
    }
    
    // MARK: - Advanced Analytics
    
    func getTimeAnalysis(accountId: UUID) async throws -> TimeAnalysis {
        _ = try requireSession()
        await simulateLatency()
        
        seedTradesIfNeeded(for: accountId)
        let allTrades = tradesByAccount[accountId] ?? []
        let closedTrades = allTrades.filter { $0.closeTime != nil }
        
        let calendar = Calendar.current
        
        // Hourly P/L
        var hourlyPnL: [Int: (pnl: Decimal, count: Int, wins: Int)] = [:]
        for trade in closedTrades {
            guard let closeTime = trade.closeTime else { continue }
            let hour = calendar.component(.hour, from: closeTime)
            let profit = trade.profit ?? 0
            let isWin = profit > 0
            
            if hourlyPnL[hour] == nil {
                hourlyPnL[hour] = (pnl: 0, count: 0, wins: 0)
            }
            hourlyPnL[hour]?.pnl += profit
            hourlyPnL[hour]?.count += 1
            if isWin { hourlyPnL[hour]?.wins += 1 }
        }
        
        let hourlyPnLArray = (0..<24).map { hour in
            let data = hourlyPnL[hour] ?? (pnl: 0, count: 0, wins: 0)
            let winRate = data.count > 0 ? Double(data.wins) / Double(data.count) : 0.0
            return TimeAnalysis.HourlyPnL(
                hour: hour,
                pnl: roundDecimal(data.pnl, toPlaces: 2),
                tradeCount: data.count,
                winRate: winRate
            )
        }
        
        // Day of Week P/L
        var dayOfWeekPnL: [Int: (pnl: Decimal, count: Int, wins: Int)] = [:]
        for trade in closedTrades {
            guard let closeTime = trade.closeTime else { continue }
            let dayOfWeek = calendar.component(.weekday, from: closeTime) // 1=Sunday, 2=Monday...
            let adjustedDay = dayOfWeek == 1 ? 7 : dayOfWeek - 1 // Convert to Mon=1, Sun=7
            let profit = trade.profit ?? 0
            let isWin = profit > 0
            
            if dayOfWeekPnL[adjustedDay] == nil {
                dayOfWeekPnL[adjustedDay] = (pnl: 0, count: 0, wins: 0)
            }
            dayOfWeekPnL[adjustedDay]?.pnl += profit
            dayOfWeekPnL[adjustedDay]?.count += 1
            if isWin { dayOfWeekPnL[adjustedDay]?.wins += 1 }
        }
        
        let dayOfWeekPnLArray = (1...7).map { day in
            let data = dayOfWeekPnL[day] ?? (pnl: 0, count: 0, wins: 0)
            let winRate = data.count > 0 ? Double(data.wins) / Double(data.count) : 0.0
            return TimeAnalysis.DayOfWeekPnL(
                dayOfWeek: day,
                pnl: roundDecimal(data.pnl, toPlaces: 2),
                tradeCount: data.count,
                winRate: winRate
            )
        }
        
        // Session Stats (simplified: Asia 0-8, London 8-16, NY 16-24)
        var asiaPnL: Decimal = 0
        var asiaCount = 0
        var asiaWins = 0
        var londonPnL: Decimal = 0
        var londonCount = 0
        var londonWins = 0
        var nyPnL: Decimal = 0
        var nyCount = 0
        var nyWins = 0
        
        for trade in closedTrades {
            guard let closeTime = trade.closeTime else { continue }
            let hour = calendar.component(.hour, from: closeTime)
            let profit = trade.profit ?? 0
            let isWin = profit > 0
            
            if hour >= 0 && hour < 8 {
                asiaPnL += profit
                asiaCount += 1
                if isWin { asiaWins += 1 }
            } else if hour >= 8 && hour < 16 {
                londonPnL += profit
                londonCount += 1
                if isWin { londonWins += 1 }
            } else {
                nyPnL += profit
                nyCount += 1
                if isWin { nyWins += 1 }
            }
        }
        
        let sessionStats = TimeAnalysis.SessionStats(
            asia: TimeAnalysis.SessionStat(
                pnl: roundDecimal(asiaPnL, toPlaces: 2),
                tradeCount: asiaCount,
                winRate: asiaCount > 0 ? Double(asiaWins) / Double(asiaCount) : 0.0
            ),
            london: TimeAnalysis.SessionStat(
                pnl: roundDecimal(londonPnL, toPlaces: 2),
                tradeCount: londonCount,
                winRate: londonCount > 0 ? Double(londonWins) / Double(londonCount) : 0.0
            ),
            newYork: TimeAnalysis.SessionStat(
                pnl: roundDecimal(nyPnL, toPlaces: 2),
                tradeCount: nyCount,
                winRate: nyCount > 0 ? Double(nyWins) / Double(nyCount) : 0.0
            )
        )
        
        return TimeAnalysis(
            hourlyPnL: hourlyPnLArray,
            dayOfWeekPnL: dayOfWeekPnLArray,
            sessionStats: sessionStats
        )
    }
    
    func getPairAnalysis(accountId: UUID) async throws -> PairAnalysis {
        _ = try requireSession()
        await simulateLatency()
        
        seedTradesIfNeeded(for: accountId)
        let allTrades = tradesByAccount[accountId] ?? []
        let closedTrades = allTrades.filter { $0.closeTime != nil }
        
        // Group by symbol
        var pairData: [String: (pnl: Decimal, trades: [TradeDetail], wins: Int)] = [:]
        for trade in closedTrades {
            let symbol = trade.symbol
            let profit = trade.profit ?? 0
            let isWin = profit > 0
            
            if pairData[symbol] == nil {
                pairData[symbol] = (pnl: 0, trades: [], wins: 0)
            }
            pairData[symbol]?.pnl += profit
            pairData[symbol]?.trades.append(trade)
            if isWin { pairData[symbol]?.wins += 1 }
        }
        
        let pairs = pairData.map { symbol, data in
            let winTrades = data.trades.filter { ($0.profit ?? 0) > 0 }
            let lossTrades = data.trades.filter { ($0.profit ?? 0) < 0 }
            let avgWin = winTrades.isEmpty ? Decimal(0) : roundDecimal(winTrades.map { $0.profit ?? 0 }.reduce(Decimal(0), +) / Decimal(winTrades.count), toPlaces: 2)
            // Get absolute value of losses (Decimal doesn't conform to Comparable for abs())
            let avgLoss = lossTrades.isEmpty ? Decimal(0) : roundDecimal(lossTrades.map { (trade: TradeDetail) -> Decimal in
                let p = trade.profit ?? 0
                return p < 0 ? -p : p
            }.reduce(Decimal(0), +) / Decimal(lossTrades.count), toPlaces: 2)
            
            return PairAnalysis.PairPerformance(
                symbol: symbol,
                pnl: roundDecimal(data.pnl, toPlaces: 2),
                tradeCount: data.trades.count,
                winRate: data.trades.count > 0 ? Double(data.wins) / Double(data.trades.count) : 0.0,
                avgWin: avgWin,
                avgLoss: avgLoss
            )
        }.sorted { $0.pnl > $1.pnl }
        
        let topPairs = Array(pairs.prefix(5))
        let worstPairs = Array(pairs.suffix(5).reversed())
        
        return PairAnalysis(
            pairs: pairs,
            topPairs: topPairs,
            worstPairs: worstPairs
        )
    }
    
    func getBehaviorAnalysis(accountId: UUID) async throws -> BehaviorAnalysis {
        _ = try requireSession()
        await simulateLatency()
        
        seedTradesIfNeeded(for: accountId)
        let allTrades = tradesByAccount[accountId] ?? []
        let closedTrades = allTrades.filter { $0.closeTime != nil }
        
        // Hold time analysis
        var winHoldTimes: [TimeInterval] = []
        var lossHoldTimes: [TimeInterval] = []
        
        for trade in closedTrades {
            guard let closeTime = trade.closeTime else { continue }
            let holdTime = closeTime.timeIntervalSince(trade.openTime)
            let profit = trade.profit ?? 0
            
            if profit > 0 {
                winHoldTimes.append(holdTime)
            } else if profit < 0 {
                lossHoldTimes.append(holdTime)
            }
        }
        
        let avgWinHoldTime = winHoldTimes.isEmpty ? 0 : winHoldTimes.reduce(0, +) / Double(winHoldTimes.count)
        let avgLossHoldTime = lossHoldTimes.isEmpty ? 0 : lossHoldTimes.reduce(0, +) / Double(lossHoldTimes.count)
        let medianWinHoldTime = winHoldTimes.isEmpty ? 0 : winHoldTimes.sorted()[winHoldTimes.count / 2]
        let medianLossHoldTime = lossHoldTimes.isEmpty ? 0 : lossHoldTimes.sorted()[lossHoldTimes.count / 2]
        
        // Revenge trading: losing trades held 2x longer
        let revengeTradingDetected = !lossHoldTimes.isEmpty && !winHoldTimes.isEmpty && avgLossHoldTime > avgWinHoldTime * 1.8
        
        // Overtrading: more than 10 trades in last 24 hours
        let last24Hours = Date().addingTimeInterval(-86400)
        let recentTrades = closedTrades.filter { ($0.closeTime ?? $0.openTime) > last24Hours }
        let overtradingDetected = recentTrades.count > 10
        
        return BehaviorAnalysis(
            holdTimeStats: BehaviorAnalysis.HoldTimeStats(
                avgWinHoldTime: avgWinHoldTime,
                avgLossHoldTime: avgLossHoldTime,
                medianWinHoldTime: medianWinHoldTime,
                medianLossHoldTime: medianLossHoldTime
            ),
            revengeTradingDetected: revengeTradingDetected,
            overtradingDetected: overtradingDetected,
            avgSlippage: nil, // Not available in mock
            avgSpreadImpact: nil // Not available in mock
        )
    }
    
    func getRiskAnalysis(accountId: UUID) async throws -> RiskAnalysis {
        _ = try requireSession()
        await simulateLatency()
        
        seedTradesIfNeeded(for: accountId)
        let allTrades = tradesByAccount[accountId] ?? []
        let closedTrades = allTrades.filter { $0.closeTime != nil }
        
        let startingEquity = Decimal(10000)
        var riskPercents: [Double] = []
        var pairExposure: [String: Decimal] = [:]
        var consecutiveLosses = 0
        var maxConsecutiveLosses = 0
        var tempConsecutive = 0
        
        // Calculate risk per trade (simplified: based on profit as % of equity)
        var runningEquity = startingEquity
        for trade in closedTrades.sorted(by: { ($0.closeTime ?? $0.openTime) < ($1.closeTime ?? $1.openTime) }) {
            let profit = trade.profit ?? 0
            let profitDouble = (profit as NSDecimalNumber).doubleValue
            let equityDouble = (runningEquity as NSDecimalNumber).doubleValue
            let riskPercent = abs(profitDouble / equityDouble * 100)
            riskPercents.append(riskPercent)
            runningEquity += profit
            
            // Track exposure by pair
            let volume = trade.volume ?? 0
            pairExposure[trade.symbol, default: 0] += volume
            
            // Track consecutive losses
            if profit < 0 {
                tempConsecutive += 1
                maxConsecutiveLosses = max(maxConsecutiveLosses, tempConsecutive)
            } else {
                if tempConsecutive > consecutiveLosses {
                    consecutiveLosses = tempConsecutive
                }
                tempConsecutive = 0
            }
        }
        if tempConsecutive > consecutiveLosses {
            consecutiveLosses = tempConsecutive
        }
        
        let avgRisk = riskPercents.isEmpty ? 0 : riskPercents.reduce(0, +) / Double(riskPercents.count)
        let maxRisk = riskPercents.max() ?? 0
        let minRisk = riskPercents.min() ?? 0
        
        // Calculate exposure % by pair
        let totalExposure = pairExposure.values.reduce(Decimal(0), +)
        let exposureByPair = pairExposure.map { symbol, exposure in
            let percent = totalExposure > 0 ? (exposure as NSDecimalNumber).doubleValue / (totalExposure as NSDecimalNumber).doubleValue * 100 : 0
            return RiskAnalysis.ExposureByPair(symbol: symbol, exposurePercent: percent)
        }.sorted { $0.exposurePercent > $1.exposurePercent }
        
        // Daily loss limit hit rate (simplified: days with loss > 5% of equity)
        let calendar = Calendar.current
        var dailyLosses: [Decimal] = []
        var daysWithLargeLoss = 0
        var totalDays = 0
        
        let groupedByDay = Dictionary(grouping: closedTrades) { trade in
            calendar.startOfDay(for: trade.closeTime ?? trade.openTime)
        }
        
        for (_, trades) in groupedByDay {
            let dayPnL = trades.compactMap { $0.profit }.reduce(Decimal(0), +)
            dailyLosses.append(dayPnL)
            totalDays += 1
            if dayPnL < -500 { // 5% of 10000
                daysWithLargeLoss += 1
            }
        }
        
        let dailyLossLimitHitRate = totalDays > 0 ? Double(daysWithLargeLoss) / Double(totalDays) : 0.0
        
        return RiskAnalysis(
            riskPerTrade: RiskAnalysis.RiskPerTrade(
                avgRiskPercent: avgRisk,
                maxRiskPercent: maxRisk,
                minRiskPercent: minRisk
            ),
            exposureByPair: exposureByPair,
            consecutiveLosses: consecutiveLosses,
            dailyLossLimitHitRate: dailyLossLimitHitRate
        )
    }
    
    private func formatDecimal(_ v: Decimal) -> String {
        let n = NSDecimalNumber(decimal: v)
        return n.stringValue
    }
}


