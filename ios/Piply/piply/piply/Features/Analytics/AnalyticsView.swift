import SwiftUI
import Charts

struct AnalyticsView: View {
    let env: AppEnvironment
    @StateObject private var vm: AnalyticsViewModel
    
    @State private var selectedHour: Int?
    @State private var selectedPair: String?

    init(env: AppEnvironment) {
        self.env = env
        _vm = StateObject(wrappedValue: AnalyticsViewModel(env: env))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.xl * 1.5) {
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
                    VStack(spacing: DS.Spacing.xl * 1.5) {
                        // Overview Section
                        if let summary = vm.summary {
                            overviewSection(summary: summary)
                                .padding(.horizontal, DS.Spacing.l)
                        }
                        
                        // Time Analysis Section
                        if let timeAnalysis = vm.timeAnalysis {
                            timeAnalysisSection(analysis: timeAnalysis)
                                .padding(.horizontal, DS.Spacing.l)
                        }
                        
                        // Pair Analysis Section
                        if let pairAnalysis = vm.pairAnalysis {
                            pairAnalysisSection(analysis: pairAnalysis)
                                .padding(.horizontal, DS.Spacing.l)
                        }
                        
                        // Behavior Analysis Section
                        if let behaviorAnalysis = vm.behaviorAnalysis {
                            behaviorAnalysisSection(analysis: behaviorAnalysis)
                                .padding(.horizontal, DS.Spacing.l)
                        }
                        
                        // Risk Analysis Section
                        if let riskAnalysis = vm.riskAnalysis {
                            riskAnalysisSection(analysis: riskAnalysis)
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
                    Text(selectedAccount.broker)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DS.ColorToken.textPrimary)
                } else {
                    Text("Select")
                        .font(.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(DS.ColorToken.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(DS.ColorToken.card.opacity(0.6))
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Overview Section
    private func overviewSection(summary: AnalyticsSummary) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader(title: "Overview", icon: "chart.bar.fill")
            
            let cols = [GridItem(.flexible(), spacing: DS.Spacing.m), GridItem(.flexible(), spacing: DS.Spacing.m)]
            LazyVGrid(columns: cols, spacing: DS.Spacing.m) {
                MetricCard(
                    title: "Total Trades",
                    value: "\(summary.tradeCount)",
                    change: nil,
                    icon: "list.bullet.rectangle.fill",
                    color: DS.ColorToken.metricTeal
                )
                
                MetricCard(
                    title: "Net P/L",
                    value: formatDecimal(summary.pnlTotal),
                    change: summary.pnlTotal >= 0 ? "+\(formatDecimal(summary.pnlTotal))" : formatDecimal(summary.pnlTotal),
                    icon: "dollarsign.circle.fill",
                    color: summary.pnlTotal >= 0 ? DS.ColorToken.metricGreen : DS.ColorToken.metricPink,
                    percentage: {
                        if let equity = summary.equity, equity > 0 {
                            let percent = (summary.pnlTotal as NSDecimalNumber).doubleValue / (equity as NSDecimalNumber).doubleValue * 100
                            let sign = summary.pnlTotal >= 0 ? "+" : ""
                            return "\(sign)\(String(format: "%.2f", percent))%"
                        }
                        return nil
                    }()
                )
                
                if let profitFactor = summary.profitFactor {
                    MetricCard(
                        title: "Profit Factor",
                        value: String(format: "%.2f", profitFactor),
                        change: nil,
                        icon: "chart.bar.fill",
                        color: profitFactor >= 1.0 ? DS.ColorToken.metricGreen : DS.ColorToken.metricOrange,
                        tooltip: "Profit Factor = Gross Profit / Gross Loss. A value above 1.0 means you're making more on winning trades than losing on losing trades. Higher is better."
                    )
                }
                
                if let expectancy = summary.expectancy {
                    MetricCard(
                        title: "Expectancy",
                        value: formatDecimal(expectancy),
                        change: nil,
                        icon: "arrow.up.arrow.down.circle.fill",
                        color: expectancy >= 0 ? DS.ColorToken.metricGreen : DS.ColorToken.metricPink,
                        tooltip: "Expectancy = (Win Rate × Avg Win) - (Loss Rate × Avg Loss). This is the expected value per trade. Positive expectancy means your strategy is profitable over time."
                    )
                }
                
                MetricCard(
                    title: "Max Drawdown",
                    value: formatDecimal(summary.maxDrawdown),
                    change: nil,
                    icon: "arrow.down.circle.fill",
                    color: DS.ColorToken.metricOrange,
                    tooltip: "Maximum Drawdown is the largest peak-to-trough decline in your account equity. It shows the worst losing streak from a high point. Lower is better for risk management."
                )
                
                if let avgRR = summary.avgRR {
                    MetricCard(
                        title: "Avg R:R",
                        value: String(format: "1:%.1f", avgRR),
                        change: nil,
                        icon: "arrow.left.arrow.right.circle.fill",
                        color: avgRR >= 1.0 ? DS.ColorToken.metricGreen : DS.ColorToken.metricOrange,
                        tooltip: "Average Risk:Reward Ratio compares your average winning trade to your average losing trade. A ratio of 1:2 means you make $2 for every $1 you risk. Higher ratios indicate better risk management."
                    )
                }
            }
        }
    }
    
    // MARK: - Time Analysis Section
    private func timeAnalysisSection(analysis: TimeAnalysis) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader(title: "Time Analysis", icon: "clock.fill")
            
            // Session Stats
            sessionStatsView(sessionStats: analysis.sessionStats)
            
            // Day of Week Stats
            dayOfWeekChart(dayOfWeekPnL: analysis.dayOfWeekPnL)
        }
    }
    
    private func sessionStatsView(sessionStats: TimeAnalysis.SessionStats) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Session Performance")
                .font(.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)
                .padding(.horizontal, DS.Spacing.l)
            
            VStack(spacing: DS.Spacing.s) {
                sessionStatRow(name: "Asia", stat: sessionStats.asia, color: DS.ColorToken.metricTeal)
                sessionStatRow(name: "London", stat: sessionStats.london, color: DS.ColorToken.metricPurple)
                sessionStatRow(name: "New York", stat: sessionStats.newYork, color: DS.ColorToken.metricOrange)
            }
            .card()
        }
    }
    
    private func sessionStatRow(name: String, stat: TimeAnalysis.SessionStat, color: Color) -> some View {
        HStack {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.ColorToken.textPrimary)
                .frame(width: 80, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDecimal(stat.pnl))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(stat.pnl >= 0 ? DS.ColorToken.success : DS.ColorToken.danger)
                Text("\(stat.tradeCount) trades • \(String(format: "%.0f%%", stat.winRate * 100)) WR")
                    .font(.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
            }
            
            Spacer()
        }
        .padding(DS.Spacing.m)
    }
    
    private func dayOfWeekChart(dayOfWeekPnL: [TimeAnalysis.DayOfWeekPnL]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("P/L by Day of Week")
                .font(.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)
                .padding(.horizontal, DS.Spacing.l)
            
            Chart(dayOfWeekPnL) { item in
                BarMark(
                    x: .value("Day", dayName(item.dayOfWeek)),
                    y: .value("P/L", (item.pnl as NSDecimalNumber).doubleValue)
                )
                .foregroundStyle((item.pnl as NSDecimalNumber).doubleValue >= 0 ? DS.ColorToken.success : DS.ColorToken.danger)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .padding(DS.Spacing.l)
            .card()
        }
    }
    
    private func dayName(_ dayOfWeek: Int) -> String {
        let days = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[safe: dayOfWeek] ?? "\(dayOfWeek)"
    }
    
    // MARK: - Pair Analysis Section
    private func pairAnalysisSection(analysis: PairAnalysis) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader(title: "Pair / Instrument", icon: "chart.bar.fill")
            
            // Top Pairs
            if !analysis.topPairs.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Top Pairs")
                        .font(.headline)
                        .foregroundStyle(DS.ColorToken.textPrimary)
                        .padding(.horizontal, DS.Spacing.l)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(analysis.topPairs.enumerated()), id: \.element.id) { index, pair in
                            pairRow(pair: pair, isTop: true)
                            if index < analysis.topPairs.count - 1 {
                                Divider()
                                    .background(DS.ColorToken.border)
                                    .padding(.leading, DS.Spacing.l)
                            }
                        }
                    }
                    .card()
                }
            }
            
            // Worst Pairs
            if !analysis.worstPairs.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Worst Pairs")
                        .font(.headline)
                        .foregroundStyle(DS.ColorToken.textPrimary)
                        .padding(.horizontal, DS.Spacing.l)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(analysis.worstPairs.enumerated()), id: \.element.id) { index, pair in
                            pairRow(pair: pair, isTop: false)
                            if index < analysis.worstPairs.count - 1 {
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
    }
    
    private func pairRow(pair: PairAnalysis.PairPerformance, isTop: Bool) -> some View {
        NavigationLink {
            TradesView(env: env)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pair.symbol)
                        .font(.headline)
                        .foregroundStyle(DS.ColorToken.textPrimary)
                    Text("\(pair.tradeCount) trades • \(String(format: "%.0f%%", pair.winRate * 100)) WR")
                        .font(.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatDecimal(pair.pnl))
                        .font(.headline)
                        .foregroundStyle(pair.pnl >= 0 ? DS.ColorToken.success : DS.ColorToken.danger)
                    Text("\(formatDecimal(pair.avgWin)) / \(formatDecimal(pair.avgLoss))")
                        .font(.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
            }
            .padding(DS.Spacing.l)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Behavior Analysis Section
    private func behaviorAnalysisSection(analysis: BehaviorAnalysis) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader(title: "Trade Behavior", icon: "brain.head.profile")
            
            // Hold Time Comparison
            holdTimeComparison(holdTimeStats: analysis.holdTimeStats)
            
            // Warnings
            if analysis.revengeTradingDetected || analysis.overtradingDetected {
                VStack(spacing: DS.Spacing.s) {
                    if analysis.revengeTradingDetected {
                        warningCard(
                            icon: "exclamationmark.triangle.fill",
                            title: "Revenge Trading Detected",
                            message: "Losing trades are held 2x longer than winning trades",
                            color: DS.ColorToken.danger
                        )
                    }
                    
                    if analysis.overtradingDetected {
                        warningCard(
                            icon: "arrow.clockwise.circle.fill",
                            title: "Overtrading Detected",
                            message: "Trading frequency is above optimal range",
                            color: DS.ColorToken.warning
                        )
                    }
                }
            }
        }
    }
    
    private func holdTimeComparison(holdTimeStats: BehaviorAnalysis.HoldTimeStats) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Hold Time Analysis")
                .font(.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)
                .padding(.horizontal, DS.Spacing.l)
            
            HStack(spacing: DS.Spacing.m) {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Winning Trades")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.ColorToken.textPrimary)
                    Text(formatTimeInterval(holdTimeStats.avgWinHoldTime))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(DS.ColorToken.success)
                    Text("Average")
                        .font(.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(DS.Spacing.m)
                .card(color: DS.ColorToken.success)
                
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Losing Trades")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.ColorToken.textPrimary)
                    Text(formatTimeInterval(holdTimeStats.avgLossHoldTime))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(DS.ColorToken.danger)
                    Text("Average")
                        .font(.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(DS.Spacing.m)
                .card(color: DS.ColorToken.danger)
            }
        }
    }
    
    private func warningCard(icon: String, title: String, message: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.s) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(DS.ColorToken.textSecondary)
            }
            Spacer()
        }
        .padding(DS.Spacing.m)
        .card(color: color)
    }
    
    // MARK: - Risk Analysis Section
    private func riskAnalysisSection(analysis: RiskAnalysis) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader(title: "Risk Analysis", icon: "exclamationmark.triangle.fill")
            
            // Risk Per Trade
            riskPerTradeView(riskPerTrade: analysis.riskPerTrade)
            
            // Exposure by Pair
            if !analysis.exposureByPair.isEmpty {
                exposureByPairView(exposure: analysis.exposureByPair)
            }
            
            // Consecutive Losses & Daily Loss Limit
            VStack(spacing: DS.Spacing.s) {
                if analysis.consecutiveLosses > 0 {
                    MetricCard(
                        title: "Consecutive Losses",
                        value: "\(analysis.consecutiveLosses)",
                        change: nil,
                        icon: "arrow.down.square.fill",
                        color: analysis.consecutiveLosses > 3 ? DS.ColorToken.metricPink : DS.ColorToken.metricOrange
                    )
                }
                
                if analysis.dailyLossLimitHitRate > 0 {
                    MetricCard(
                        title: "Daily Loss Limit Hit",
                        value: String(format: "%.0f%%", analysis.dailyLossLimitHitRate * 100),
                        change: nil,
                        icon: "exclamationmark.octagon.fill",
                        color: DS.ColorToken.metricOrange
                    )
                }
            }
        }
    }
    
    private func riskPerTradeView(riskPerTrade: RiskAnalysis.RiskPerTrade) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Risk Per Trade")
                .font(.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)
                .padding(.horizontal, DS.Spacing.l)
            
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                HStack {
                    Text("Average")
                        .font(.subheadline)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                    Spacer()
                    Text(String(format: "%.2f%%", riskPerTrade.avgRiskPercent))
                        .font(.headline)
                        .foregroundStyle(DS.ColorToken.textPrimary)
                }
                
                HStack {
                    Text("Range")
                        .font(.subheadline)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                    Spacer()
                    Text(String(format: "%.2f%% - %.2f%%", riskPerTrade.minRiskPercent, riskPerTrade.maxRiskPercent))
                        .font(.subheadline)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
            }
            .padding(DS.Spacing.m)
            .card()
        }
    }
    
    private func exposureByPairView(exposure: [RiskAnalysis.ExposureByPair]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Exposure by Pair")
                .font(.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)
                .padding(.horizontal, DS.Spacing.l)
            
            Chart(exposure) { item in
                BarMark(
                    x: .value("Pair", item.symbol),
                    y: .value("Exposure", item.exposurePercent)
                )
                .foregroundStyle(DS.ColorToken.metricOrange)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .padding(DS.Spacing.l)
            .card()
        }
    }
    
    // MARK: - Helpers
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(DS.ColorToken.accent)
            Text(title)
                .font(.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)
        }
        .padding(.bottom, DS.Spacing.xs)
    }
    
    private func formatDecimal(_ v: Decimal) -> String {
        let n = NSDecimalNumber(decimal: v)
        return n.stringValue
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
