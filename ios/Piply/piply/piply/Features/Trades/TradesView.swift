import SwiftUI

struct TradesView: View {
    let env: AppEnvironment
    @StateObject private var vm: TradesViewModel

    @State private var showFilters = false

    init(env: AppEnvironment) {
        self.env = env
        _vm = StateObject(wrappedValue: TradesViewModel(env: env))
    }

    var body: some View {
        List {
            if let error = vm.errorMessage {
                Section { ErrorView(message: error, action: { Task { await vm.refresh() } }) }
            }

            if vm.accounts.isEmpty {
                Section {
                    EmptyStateView(
                        title: "No accounts connected",
                        message: "Connect an account, then sync to see your trade history.",
                        systemImage: "link"
                    )
                }
            } else {
                Section {
                    accountPicker
                }

                if vm.trades.isEmpty {
                    Section {
                        EmptyStateView(
                            title: "No trades",
                            message: "Try changing filters, or trigger sync from Accounts.",
                            systemImage: "tray"
                        )
                    }
                } else {
                    Section("Trades") {
                        ForEach(vm.trades) { t in
                            NavigationLink {
                                TradeDetailView(env: env, tradeId: t.id)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(t.symbol)
                                            .font(.headline)
                                        Text((t.closeTime ?? t.openTime), formatter: DateFormatters.shortDateTime)
                                            .font(.caption)
                                            .foregroundStyle(DS.ColorToken.textSecondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(t.side.rawValue.uppercased())
                                            .font(.caption)
                                            .foregroundStyle(DS.ColorToken.textSecondary)
                                        Text(formatProfit(t.profit))
                                            .font(.headline)
                                            .foregroundStyle(profitColor(t.profit))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Trades")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .disabled(vm.accounts.isEmpty)
            }
        }
        .sheet(isPresented: $showFilters) {
            TradesFilterView(
                from: $vm.from,
                to: $vm.to,
                symbol: $vm.symbol,
                outcome: $vm.outcome,
                limit: $vm.limit
            )
        }
        .task { await vm.refresh() }
        .onChange(of: vm.selectedAccountId) { _, _ in Task { await vm.loadTrades() } }
        .onChange(of: vm.from) { _, _ in Task { await vm.loadTrades() } }
        .onChange(of: vm.to) { _, _ in Task { await vm.loadTrades() } }
        .onChange(of: vm.symbol) { _, _ in Task { await vm.loadTrades() } }
        .onChange(of: vm.outcome) { _, _ in Task { await vm.loadTrades() } }
        .onChange(of: vm.limit) { _, _ in Task { await vm.loadTrades() } }
        .background(DS.ColorToken.background)
    }

    private var accountPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Account")
                .font(.subheadline)
                .foregroundStyle(DS.ColorToken.textSecondary)
            Picker("Account", selection: $vm.selectedAccountId) {
                ForEach(vm.accounts) { a in
                    Text("\(a.broker) • \(a.accountId)")
                        .tag(Optional(a.id))
                }
            }
            .pickerStyle(.menu)
            .tint(DS.ColorToken.accent)
        }
    }

    private func formatProfit(_ v: Decimal?) -> String {
        guard let v else { return "—" }
        return NSDecimalNumber(decimal: v).stringValue
    }

    private func profitColor(_ v: Decimal?) -> Color {
        guard let v else { return DS.ColorToken.textTertiary }
        return v >= 0 ? DS.ColorToken.success : DS.ColorToken.danger
    }
}


