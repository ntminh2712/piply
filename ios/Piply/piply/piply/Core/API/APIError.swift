import Foundation

enum APIError: LocalizedError, Equatable, Sendable {
    case notAuthenticated
    case validation(message: String)
    case invalidCredentials
    case planLimitReached(message: String)
    case rateLimited(message: String)
    case notFound
    case unknown(message: String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You’re not logged in."
        case let .validation(message):
            return message
        case .invalidCredentials:
            return "Invalid credentials. Please check your account information and try again."
        case let .planLimitReached(message):
            return message
        case let .rateLimited(message):
            return message
        case .notFound:
            return "Not found."
        case let .unknown(message):
            return message
        }
    }
}


