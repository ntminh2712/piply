import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    @Published var isLoading = false

    func submit(_ operation: @Sendable () async throws -> Session) async -> Session? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            return try await operation()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Authentication failed."
            return nil
        }
    }
}


