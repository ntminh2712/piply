import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let api: any APIClient

    @Published private(set) var session: Session?

    init(api: any APIClient) {
        self.api = api
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


