import Foundation
import Combine

@MainActor
final class TradeDetailViewModel: ObservableObject {
    @Published var trade: TradeDetail?
    @Published var annotation: TradeAnnotation?
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var noteText: String = ""
    @Published var tags: [String] = []

    private let env: AppEnvironment
    private let tradeId: UUID

    init(env: AppEnvironment, tradeId: UUID) {
        self.env = env
        self.tradeId = tradeId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let detail = env.api.getTradeDetail(tradeId: tradeId)
            async let ann = env.api.getTradeAnnotation(tradeId: tradeId)
            trade = try await detail
            let a = try await ann
            annotation = a
            noteText = a.noteText
            tags = a.tags
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load trade."
        }
    }

    func saveAnnotation() async {
        errorMessage = nil
        do {
            let updated = try await env.api.updateTradeAnnotation(tradeId: tradeId, noteText: noteText, tags: tags)
            annotation = updated
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to save."
        }
    }
}


