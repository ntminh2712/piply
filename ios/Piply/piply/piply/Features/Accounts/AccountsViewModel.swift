import Foundation
import Combine

@MainActor
final class AccountsViewModel: ObservableObject {
    @Published var accounts: [TradingAccount] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showPaywall = false
    @Published var paywallMessage: String?

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
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load accounts."
        }
    }

    func deleteAccount(id: UUID) async {
        do {
            try await env.api.deleteTradingAccount(id: id)
            await refresh()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to delete account."
        }
    }

    func triggerSync(accountId: UUID) async {
        do {
            _ = try await env.api.triggerSync(tradingAccountId: accountId)
            await refresh()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to trigger sync."
        }
    }

    func createAccount(broker: String, server: String, accountId: String, password: String) async -> Bool {
        do {
            _ = try await env.api.createTradingAccount(broker: broker, server: server, accountId: accountId, readOnlyPassword: password)
            await refresh()
            return true
        } catch let apiError as APIError {
            switch apiError {
            case let .planLimitReached(message):
                showPaywall = true
                paywallMessage = message
            default:
                errorMessage = apiError.errorDescription
            }
            return false
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to create account."
            return false
        }
    }
}


