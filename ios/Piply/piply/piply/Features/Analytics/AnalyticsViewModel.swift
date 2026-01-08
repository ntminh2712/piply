import Foundation
import Combine

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var accounts: [TradingAccount] = []
    @Published var selectedAccountId: UUID?
    
    @Published var summary: AnalyticsSummary?
    @Published var timeAnalysis: TimeAnalysis?
    @Published var pairAnalysis: PairAnalysis?
    @Published var behaviorAnalysis: BehaviorAnalysis?
    @Published var riskAnalysis: RiskAnalysis?
    
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
            accounts = try await env.api.listTradingAccounts()
            if selectedAccountId == nil {
                selectedAccountId = accounts.first?.id
            }
            await loadAnalytics()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load analytics."
        }
    }
    
    func loadAnalytics() async {
        guard let accountId = selectedAccountId else {
            summary = nil
            timeAnalysis = nil
            pairAnalysis = nil
            behaviorAnalysis = nil
            riskAnalysis = nil
            return
        }
        
        do {
            async let s = env.api.getAnalyticsSummary(accountId: accountId, from: nil, to: nil)
            async let t = env.api.getTimeAnalysis(accountId: accountId)
            async let p = env.api.getPairAnalysis(accountId: accountId)
            async let b = env.api.getBehaviorAnalysis(accountId: accountId)
            async let r = env.api.getRiskAnalysis(accountId: accountId)
            
            summary = try await s
            timeAnalysis = try await t
            pairAnalysis = try await p
            behaviorAnalysis = try await b
            riskAnalysis = try await r
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load analytics."
        }
    }
}

