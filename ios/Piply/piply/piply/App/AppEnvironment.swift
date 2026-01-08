import Foundation
import Combine

@MainActor
final class AppEnvironment: ObservableObject {
    let api: any APIClient

    @Published private(set) var session: Session?

    init(api: any APIClient) {
        self.api = api
        
        // Auto-login with mock data for development
        Task {
            if let mock = api as? MockAPIClient {
                // Try to get existing session first
                if let existingSession = await mock.getCurrentSession() {
                    self.session = existingSession
                } else {
                    // If no session, login
                    do {
                        let mockSession = try await api.login(email: "demo@example.com", password: "demo")
                        self.session = mockSession
                    } catch {
                        // Login failed, continue without session
                    }
                }
            }
        }
    }

    var isLoggedIn: Bool { session != nil }

    func setSession(_ session: Session) {
        self.session = session
    }

    func clearSession() {
        self.session = nil
        Task { await api.logout() }
    }
}


