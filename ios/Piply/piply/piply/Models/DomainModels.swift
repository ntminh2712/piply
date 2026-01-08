import Foundation

// MARK: - Session

struct Session: Equatable, Sendable {
    let token: String
    let email: String
}

// MARK: - Trading Accounts

enum TradingAccountStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case syncing
    case synced
    case failed
}

struct TradingAccount: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var broker: String
    var server: String
    var accountId: String
    var status: TradingAccountStatus
    var lastAttemptedSyncAt: Date?
    var lastSuccessfulSyncAt: Date?
    var lastErrorMessage: String?
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - Trades

enum TradeSide: String, Codable, CaseIterable, Sendable {
    case buy
    case sell
}

struct Trade: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let tradingAccountId: UUID
    var symbol: String
    var side: TradeSide
    var openTime: Date
    var closeTime: Date?
    var profit: Decimal?
    var isOpen: Bool { closeTime == nil }
}

struct TradeDetail: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let tradingAccountId: UUID
    var symbol: String
    var side: TradeSide
    var openTime: Date
    var closeTime: Date?

    var openPrice: Decimal?
    var closePrice: Decimal?
    var volume: Decimal?
    var sl: Decimal?
    var tp: Decimal?
    var commission: Decimal?
    var swap: Decimal?

    var profit: Decimal?
}

struct TradeAnnotation: Codable, Equatable, Sendable {
    var noteText: String
    var tags: [String]
}

enum TradeOutcomeFilter: String, CaseIterable, Sendable {
    case win
    case loss
    case breakeven
}

// MARK: - Analytics

struct AnalyticsSummary: Codable, Equatable, Sendable {
    var pnlTotal: Decimal
    var winRate: Double
    var maxDrawdown: Decimal
    var tradeCount: Int
    
    // Extended metrics
    var equity: Decimal? // Current equity (if available)
    var dailyPnL: Decimal? // Today's P/L
    var profitFactor: Double? // Gross profit / Gross loss
    var avgWin: Decimal? // Average winning trade
    var avgLoss: Decimal? // Average losing trade
    var currentRisk: Decimal? // Current risk percentage
    var losingStreak: Int? // Current losing streak
    var maxLosingStreak: Int? // Maximum losing streak
    var overtradeWarning: Bool? // True if overtrading detected
}

struct EquityPoint: Codable, Equatable, Sendable, Identifiable {
    var id: String { dayISO }
    let dayISO: String // YYYY-MM-DD
    let equity: Decimal
}

struct EquitySeries: Codable, Equatable, Sendable {
    let points: [EquityPoint]
}

struct Insight: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let type: InsightType
    let title: String
    let message: String
    let severity: InsightSeverity
}

enum InsightType: String, Codable, Sendable {
    case timeBased
    case pairBased
    case behavior
}

enum InsightSeverity: String, Codable, Sendable {
    case info
    case warning
    case critical
}

struct PnlPoint: Codable, Equatable, Sendable, Identifiable {
    var id: String { dayISO }
    let dayISO: String // YYYY-MM-DD
    let pnl: Decimal
}

struct PnlSeries: Codable, Equatable, Sendable {
    enum Bucket: String, Codable, CaseIterable, Sendable {
        case daily
        case weekly
    }

    let bucket: Bucket
    let points: [PnlPoint]
}

// MARK: - Subscription

enum Plan: String, Codable, CaseIterable, Sendable {
    case free
    case pro
}

enum SubscriptionStatus: String, Codable, CaseIterable, Sendable {
    case active
    case canceled
    case pastDue
}

struct SubscriptionLimits: Codable, Equatable, Sendable {
    var maxAccounts: Int
    var manualSyncPerDay: Int
    var schedulerIntervalMinutes: Int
}

struct SubscriptionInfo: Codable, Equatable, Sendable {
    var plan: Plan
    var status: SubscriptionStatus
    var limits: SubscriptionLimits
}


