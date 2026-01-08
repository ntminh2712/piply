import SwiftUI
import Charts

struct AnalyticsView: View {
    let env: AppEnvironment
    @StateObject private var vm: DashboardViewModel

    init(env: AppEnvironment) {
        self.env = env
        _vm = StateObject(wrappedValue: DashboardViewModel(env: env))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.xl) {
                if let error = vm.errorMessage {
                    ErrorView(message: error, action: { Task { await vm.refresh() } })
                        .padding(.horizontal, DS.Spacing.l)
                }

                if vm.accounts.isEmpty {
                    EmptyStateView(
                        title: "No accounts connected",
                        message: "Connect an account to start syncing and see analytics.",
                        systemImage: "chart.bar.fill"
                    )
                    .padding(.horizontal, DS.Spacing.l)
                } else {
                    VStack(spacing: DS.Spacing.xl) {
                        // Performance Section
                        performanceSection
                            .padding(.horizontal, DS.Spacing.l)

                        // Risk Section
                        if let summary = vm.summary {
                            riskSection(summary: summary)
                                .padding(.horizontal, DS.Spacing.l)
                        }
                    }
                }
            }
            .padding(.vertical, DS.Spacing.l)
        }
        .background(DS.ColorToken.background)
        .navigationTitle("Analytics")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                accountPicker
            }
        }
        .task { await vm.refresh() }
        .onChange(of: vm.selectedAccountId) { _, _ in
            Task { await vm.loadAnalytics() }
        }
    }

    private var accountPicker: some View {
        Menu {
            ForEach(vm.accounts) { account in
                Button {
                    vm.selectedAccountId = account.id
                } label: {
                    HStack {
                        Text("\(account.broker) • \(account.accountId)")
                        if vm.selectedAccountId == account.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                if let selectedAccount = vm.accounts.first(where: { $0.id == vm.selectedAccountId }) {
                    Text("\(selectedAccount.broker) • \(selectedAccount.accountId)")
                        .font(.subheadline)
                        .foregroundStyle(DS.ColorToken.accent)
                } else {
                    Text("Select Account")
                        .font(.subheadline)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(DS.ColorToken.textSecondary)
            }
        }
    }

    // MARK: - Performance Section
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Performance")
                .font(.title2.weight(.bold))
                .foregroundStyle(DS.ColorToken.textPrimary)
            
            // Equity Curve
            if let equitySeries = vm.equitySeries {
                equityCurveChart(series: equitySeries)
            }
            
            // Daily PnL Chart
            if let series = vm.series {
                dailyPnLChart(series: series)
            }
            
            // Profit Factor & Avg Win/Loss
            if let summary = vm.summary {
                performanceMetrics(summary: summary)
            }
        }
    }
    
    private func equityCurveChart(series: EquitySeries) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Equity Curve")
                .font(.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)
                .padding(.horizontal, DS.Spacing.l)
            
            Chart(series.points) { p in
                LineMark(
                    x: .value("Day", p.dayISO),
                    y: .value("Equity", (p.equity as NSDecimalNumber).doubleValue)
                )
                .foregroundStyle(DS.ColorToken.metricPurple)
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 200)
            .padding(DS.Spacing.l)
            .card()
        }
    }
    
    private func dailyPnLChart(series: PnlSeries) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Daily P/L")
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
            .frame(height: 200)
            .padding(DS.Spacing.l)
            .card()
        }
    }
    
    private func performanceMetrics(summary: AnalyticsSummary) -> some View {
        let cols = [GridItem(.flexible(), spacing: DS.Spacing.m), GridItem(.flexible(), spacing: DS.Spacing.m)]
        return LazyVGrid(columns: cols, spacing: DS.Spacing.m) {
            if let profitFactor = summary.profitFactor {
                MetricCard(
                    title: "Profit Factor",
                    value: String(format: "%.2f", profitFactor),
                    change: nil,
                    icon: "chart.bar.fill",
                    color: profitFactor >= 1.0 ? DS.ColorToken.metricGreen : DS.ColorToken.metricOrange
                )
            }
            
            if let avgWin = summary.avgWin {
                MetricCard(
                    title: "Avg Win",
                    value: formatDecimal(avgWin),
                    change: nil,
                    icon: "arrow.up.circle.fill",
                    color: DS.ColorToken.metricGreen
                )
            }
            
            if let avgLoss = summary.avgLoss {
                MetricCard(
                    title: "Avg Loss",
                    value: formatDecimal(avgLoss),
                    change: nil,
                    icon: "arrow.down.circle.fill",
                    color: DS.ColorToken.metricPink
                )
            }
        }
    }
    
    // MARK: - Risk Section
    private func riskSection(summary: AnalyticsSummary) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Risk")
                .font(.title2.weight(.bold))
                .foregroundStyle(DS.ColorToken.textPrimary)
            
            let cols = [GridItem(.flexible(), spacing: DS.Spacing.m), GridItem(.flexible(), spacing: DS.Spacing.m)]
            LazyVGrid(columns: cols, spacing: DS.Spacing.m) {
                if let currentRisk = summary.currentRisk {
                    MetricCard(
                        title: "Current Risk",
                        value: String(format: "%.1f%%", (currentRisk as NSDecimalNumber).doubleValue),
                        change: nil,
                        icon: "exclamationmark.triangle.fill",
                        color: (currentRisk as NSDecimalNumber).doubleValue > 5 ? DS.ColorToken.metricOrange : DS.ColorToken.metricTeal
                    )
                }
                
                MetricCard(
                    title: "Max Drawdown",
                    value: formatDecimal(summary.maxDrawdown),
                    change: nil,
                    icon: "arrow.down.circle.fill",
                    color: DS.ColorToken.metricOrange
                )
                
                if let losingStreak = summary.losingStreak {
                    MetricCard(
                        title: "Losing Streak",
                        value: "\(losingStreak)",
                        change: nil,
                        icon: "arrow.down.square.fill",
                        color: losingStreak > 3 ? DS.ColorToken.metricPink : DS.ColorToken.metricOrange
                    )
                }
                
                if summary.overtradeWarning == true {
                    MetricCard(
                        title: "Overtrade Warning",
                        value: "⚠️ Active",
                        change: nil,
                        icon: "exclamationmark.triangle.fill",
                        color: DS.ColorToken.metricOrange
                    )
                }
            }
        }
    }

    private func formatDecimal(_ v: Decimal) -> String {
        let n = NSDecimalNumber(decimal: v)
        return n.stringValue
    }
}

