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

    @Published var accountHealth: AccountHealthStatus = .unknown

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
            accountHealth = .unknown
            return
        }

        do {
            async let s = env.api.getAnalyticsSummary(accountId: accountId, from: nil, to: nil)
            async let p = env.api.getPnlSeries(accountId: accountId, from: nil, to: nil, bucket: .daily)
            async let e = env.api.getEquitySeries(accountId: accountId, from: nil, to: nil)
            async let r = env.api.listTrades(accountId: accountId, from: nil, to: nil, symbol: nil, outcome: nil, limit: 10)
            async let o = env.api.getOpenTrades(accountId: accountId)
            async let i = env.api.getInsights(accountId: accountId)
            
            let fetchedSummary = try await s
            summary = fetchedSummary
            series = try await p
            equitySeries = try await e
            recentTrades = try await r
            openTrades = try await o
            insights = try await i
            
            accountHealth = calculateAccountHealth(summary: fetchedSummary)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load analytics."
        }
    }
    
    private func calculateAccountHealth(summary: AnalyticsSummary) -> AccountHealthStatus {
        let equity = summary.equity ?? Decimal(10000)
        let startingEquity = Decimal(10000)
        let dd = summary.maxDrawdown
        let ddPercent = (dd as NSDecimalNumber).doubleValue / (startingEquity as NSDecimalNumber).doubleValue * 100
        
        if ddPercent < 3 && (summary.losingStreak ?? 0) < 3 {
            return .healthy(drawdownPercent: ddPercent)
        } else if ddPercent < 7 && (summary.losingStreak ?? 0) < 5 {
            return .warning(drawdownPercent: ddPercent)
        } else {
            return .risk(drawdownPercent: ddPercent)
        }
    }

    enum AccountHealthStatus: Equatable {
        case unknown
        case healthy(drawdownPercent: Double)
        case warning(drawdownPercent: Double)
        case risk(drawdownPercent: Double)
        
        var title: String {
            switch self {
            case .unknown: return "Account Status Unknown"
            case .healthy: return "Account Healthy"
            case .warning: return "Account Warning"
            case .risk: return "Account Risk"
            }
        }
        
        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle.fill"
            case .healthy: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .risk: return "exclamationmark.octagon.fill"
            }
        }
        
        var message: String {
            switch self {
            case .unknown: return "No data available"
            case .healthy(let dd): return "Max DD: \(String(format: "%.1f%%", dd)) (Safe)"
            case .warning(let dd): return "Max DD: \(String(format: "%.1f%%", dd)) (Monitor)"
            case .risk(let dd): return "Max DD: \(String(format: "%.1f%%", dd)) (High Risk)"
            }
        }
        
        var drawdownPercent: Double? {
            switch self {
            case .unknown: return nil
            case .healthy(let dd), .warning(let dd), .risk(let dd): return dd
            }
        }
    }
}


