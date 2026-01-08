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
        ScrollView {
            VStack(spacing: DS.Spacing.xl) {
                // Info Banner
                if !vm.accounts.isEmpty {
                    InfoBanner(text: "Read-only journal. Sync is delayed; it may take a few minutes. Metrics are based on realized trades.")
                        .padding(.horizontal, DS.Spacing.l)
                }

                if let error = vm.errorMessage {
                    ErrorView(message: error, action: { Task { await vm.refresh() } })
                        .padding(.horizontal, DS.Spacing.l)
                }

                if vm.accounts.isEmpty {
                    EmptyStateView(
                        title: "No accounts connected",
                        message: "Connect an account to start syncing and unlock your dashboard.",
                        systemImage: "link",
                        actionTitle: "Go to Accounts",
                        action: { vm.requestGoToAccounts = true }
                    )
                    .padding(.horizontal, DS.Spacing.l)
                } else {
                    VStack(spacing: DS.Spacing.xl) {
                        // Account Picker
                        accountPicker
                            .padding(.horizontal, DS.Spacing.l)

                        // Metric Cards - inspired by dashboard
                        if let summary = vm.summary {
                            metricCardsSection(summary: summary)
                                .padding(.horizontal, DS.Spacing.l)
                        }

                        // Chart Section
                        if let series = vm.series {
                            chartSection(series: series)
                                .padding(.horizontal, DS.Spacing.l)
                        }

                        // Recent Trades
                        recentTradesSection
                            .padding(.horizontal, DS.Spacing.l)
                    }
                }
            }
            .padding(.vertical, DS.Spacing.l)
        }
        .background(DS.ColorToken.background)
        .navigationTitle("Dashboard")
        .task { await vm.refresh() }
        .onChange(of: vm.selectedAccountId) { _, _ in
            Task { await vm.loadAnalytics() }
        }
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
        .card()
    }

    private func metricCardsSection(summary: AnalyticsSummary) -> some View {
        let cols = [GridItem(.flexible(), spacing: DS.Spacing.m), GridItem(.flexible(), spacing: DS.Spacing.m)]
        return LazyVGrid(columns: cols, spacing: DS.Spacing.m) {
            MetricCard(
                title: "Total P/L",
                value: formatDecimal(summary.pnlTotal),
                change: nil,
                icon: "dollarsign.circle.fill",
                color: summary.pnlTotal >= 0 ? DS.ColorToken.metricGreen : DS.ColorToken.metricPink
            )
            
            MetricCard(
                title: "Win Rate",
                value: String(format: "%.0f%%", summary.winRate * 100),
                change: nil,
                icon: "target",
                color: DS.ColorToken.metricPurple
            )
            
            MetricCard(
                title: "Max Drawdown",
                value: formatDecimal(summary.maxDrawdown),
                change: nil,
                icon: "arrow.down.circle.fill",
                color: DS.ColorToken.metricOrange
            )
            
            MetricCard(
                title: "Total Trades",
                value: "\(summary.tradeCount)",
                change: nil,
                icon: "list.bullet.rectangle.fill",
                color: DS.ColorToken.metricTeal
            )
        }
    }

    private func chartSection(series: PnlSeries) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("P/L over time")
                .font(.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)
                .padding(.horizontal, DS.Spacing.l)
            
            Chart(series.points) { p in
                BarMark(
                    x: .value("Day", p.dayISO),
                    y: .value("P/L", (p.pnl as NSDecimalNumber).doubleValue)
                )
                .foregroundStyle((p.pnl as NSDecimalNumber).doubleValue >= 0 ? DS.ColorToken.success : DS.ColorToken.danger)
                .cornerRadius(4)
            }
            .frame(height: 220)
            .padding(DS.Spacing.l)
            .card()
        }
    }

    private var recentTradesSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Recent trades")
                .font(.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)
                .padding(.horizontal, DS.Spacing.l)
            
            if vm.recentTrades.isEmpty {
                Text("No trades yet — trigger sync from Accounts.")
                    .foregroundStyle(DS.ColorToken.textSecondary)
                    .padding(DS.Spacing.l)
                    .frame(maxWidth: .infinity)
                    .card()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.recentTrades.enumerated()), id: \.element.id) { index, trade in
                        NavigationLink {
                            TradeDetailView(env: env, tradeId: trade.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(trade.symbol)
                                        .font(.headline)
                                        .foregroundStyle(DS.ColorToken.textPrimary)
                                    Text(trade.side.rawValue.uppercased())
                                        .font(.caption)
                                        .foregroundStyle(DS.ColorToken.textSecondary)
                                }
                                Spacer()
                                Text(formatProfit(trade.profit))
                                    .font(.headline)
                                    .foregroundStyle(profitColor(trade.profit))
                            }
                            .padding(DS.Spacing.l)
                        }
                        .buttonStyle(.plain)
                        
                        if index < vm.recentTrades.count - 1 {
                            Divider()
                                .background(DS.ColorToken.border)
                                .padding(.leading, DS.Spacing.l)
                        }
                    }
                }
                .card()
            }
        }
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
        guard let v else { return DS.ColorToken.textTertiary }
        return v >= 0 ? DS.ColorToken.success : DS.ColorToken.danger
    }
}


