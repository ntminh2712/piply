import SwiftUI
import Charts

struct DashboardView: View {
    let env: AppEnvironment
    @StateObject private var vm: DashboardViewModel

    init(env: AppEnvironment) {
        self.env = env
        _vm = StateObject(wrappedValue: DashboardViewModel(env: env))
    }

    var body: some View {
        List {
            Section {
                InfoBanner(text: "Read-only journal. Sync is delayed; it may take a few minutes. Metrics are based on realized trades.")
            }

            if let error = vm.errorMessage {
                Section {
                    ErrorView(message: error, action: { Task { await vm.refresh() } })
                }
            }

            if vm.accounts.isEmpty {
                Section {
                    EmptyStateView(
                        title: "No accounts connected",
                        message: "Connect an account to start syncing and unlock your dashboard.",
                        systemImage: "link",
                        actionTitle: "Go to Accounts",
                        action: { vm.requestGoToAccounts = true }
                    )
                }
            } else {
                Section {
                    accountPicker
                }

                if let summary = vm.summary {
                    Section("Summary") {
                        kpiGrid(summary: summary)
                    }
                }

                if let series = vm.series {
                    Section("P/L over time") {
                        Chart(series.points) { p in
                            BarMark(
                                x: .value("Day", p.dayISO),
                                y: .value("P/L", (p.pnl as NSDecimalNumber).doubleValue)
                            )
                            .foregroundStyle((p.pnl as NSDecimalNumber).doubleValue >= 0 ? DS.ColorToken.success : DS.ColorToken.danger)
                            .cornerRadius(4)
                        }
                        .frame(height: 190)
                        .padding(.vertical, 6)
                    }
                }

                Section("Recent trades") {
                    if vm.recentTrades.isEmpty {
                        Text("No trades yet — trigger sync from Accounts.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.recentTrades) { t in
                            NavigationLink {
                                TradeDetailView(env: env, tradeId: t.id)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(t.symbol)
                                            .font(.headline)
                                        Text(t.side.rawValue.uppercased())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
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
        .listStyle(.insetGrouped)
        .navigationTitle("Dashboard")
        .task { await vm.refresh() }
        .onChange(of: vm.selectedAccountId) { _, _ in
            Task { await vm.loadAnalytics() }
        }
        .background(DS.ColorToken.background)
    }

    private var accountPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Account")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Picker("Account", selection: $vm.selectedAccountId) {
                ForEach(vm.accounts) { a in
                    Text("\(a.broker) • \(a.accountId)")
                        .tag(Optional(a.id))
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func kpiGrid(summary: AnalyticsSummary) -> some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 12) {
            kpiCard(title: "Total P/L", value: formatDecimal(summary.pnlTotal), color: summary.pnlTotal >= 0 ? .green : .red)
            kpiCard(title: "Win rate", value: String(format: "%.0f%%", summary.winRate * 100), color: .blue)
            kpiCard(title: "Max drawdown", value: formatDecimal(summary.maxDrawdown), color: .orange)
            kpiCard(title: "Trades", value: "\(summary.tradeCount)", color: .gray)
        }
        .padding(.vertical, 4)
    }

    private func kpiCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func formatDecimal(_ v: Decimal) -> String {
        let n = NSDecimalNumber(decimal: v)
        return n.stringValue
    }

    private func formatProfit(_ v: Decimal?) -> String {
        guard let v else { return "—" }
        return formatDecimal(v)
    }

    private func profitColor(_ v: Decimal?) -> Color {
        guard let v else { return .secondary }
        return v >= 0 ? .green : .red
    }
}


