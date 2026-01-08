import SwiftUI

struct TradeDetailView: View {
    let env: AppEnvironment
    let tradeId: UUID

    @StateObject private var vm: TradeDetailViewModel

    init(env: AppEnvironment, tradeId: UUID) {
        self.env = env
        self.tradeId = tradeId
        _vm = StateObject(wrappedValue: TradeDetailViewModel(env: env, tradeId: tradeId))
    }

    var body: some View {
        List {
            if let error = vm.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            if let t = vm.trade {
                Section("Trade") {
                    row("Symbol", t.symbol)
                    row("Side", t.side.rawValue.uppercased())
                    row("Open time", DateFormatters.shortDateTime.string(from: t.openTime))
                    row("Close time", t.closeTime.map { DateFormatters.shortDateTime.string(from: $0) } ?? "—")
                    row("Profit", formatDecimal(t.profit))
                    row("Volume", formatDecimal(t.volume))
                    row("SL / TP", "\(formatDecimal(t.sl)) / \(formatDecimal(t.tp))")
                }
            } else if vm.isLoading {
                Section { ProgressView("Loading…") }
            }

            Section("Journal") {
                TextEditor(text: $vm.noteText)
                    .frame(minHeight: 100)
                TagEditorView(tags: $vm.tags)
            }

            Section {
                PrimaryButton(title: "Save journal", isLoading: vm.isLoading) {
                    Task { await vm.saveAnnotation() }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Trade detail")
        .task { await vm.load() }
        .background(DS.ColorToken.background)
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k)
                .foregroundStyle(.secondary)
            Spacer()
            Text(v)
        }
    }

    private func formatDecimal(_ v: Decimal?) -> String {
        guard let v else { return "—" }
        return NSDecimalNumber(decimal: v).stringValue
    }
}


