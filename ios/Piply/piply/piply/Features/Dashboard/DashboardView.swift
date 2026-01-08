import SwiftUI
import Charts

struct DashboardView: View {
    let env: AppEnvironment
    @StateObject private var vm: DashboardViewModel
    @State private var selectedEquityPoint: (day: String, equity: Double)?
    @State private var selectedPnlPoint: (day: String, pnl: Double)?

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
                        message: "Connect an account to start syncing and unlock your dashboard.",
                        systemImage: "link",
                        actionTitle: "Go to Accounts",
                        action: { vm.requestGoToAccounts = true }
                    )
                    .padding(.horizontal, DS.Spacing.l)
                } else {
                    VStack(spacing: DS.Spacing.xl * 1.5) {
                        // Today's Focus
                        if !vm.insights.isEmpty {
                            todaysFocusSection
                                .padding(.horizontal, DS.Spacing.l)
                        }
                        
                        // Insights Section
                        insightsSection
                            .padding(.horizontal, DS.Spacing.l)
                            .padding(.top, DS.Spacing.s)

                        // Snapshot Section
                        if let summary = vm.summary {
                            snapshotSection(summary: summary)
                                .padding(.horizontal, DS.Spacing.l)
                        }

                        // Performance Section
                        performanceSection
                            .padding(.horizontal, DS.Spacing.l)

                        // Risk Section
                        if let summary = vm.summary {
                            riskSection(summary: summary)
                                .padding(.horizontal, DS.Spacing.l)
                        }

                        // Activity Section
                        activitySection
                            .padding(.horizontal, DS.Spacing.l)
                    }
                }
            }
            .padding(.vertical, DS.Spacing.l)
        }
        .background(DS.ColorToken.background)
        .navigationTitle("Dashboard")
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
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "link.circle.fill")
                                    .foregroundStyle(DS.ColorToken.accent)
                                Text(account.broker)
                                    .font(.subheadline.weight(.semibold))
                                Circle()
                                    .fill(account.status == .synced ? DS.ColorToken.success : DS.ColorToken.warning)
                                    .frame(width: 6, height: 6)
                            }
                            Text(account.accountId)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let equity = vm.summary?.equity, account.id == vm.selectedAccountId {
                                Text("Equity: \(formatDecimal(equity))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if vm.selectedAccountId == account.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(DS.ColorToken.accent)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                if let selectedAccount = vm.accounts.first(where: { $0.id == vm.selectedAccountId }) {
                    Image(systemName: "link.circle.fill")
                        .font(.caption)
                        .foregroundStyle(DS.ColorToken.accent)
                    Text(selectedAccount.broker)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DS.ColorToken.textPrimary)
                    Circle()
                        .fill(selectedAccount.status == .synced ? DS.ColorToken.success : DS.ColorToken.warning)
                        .frame(width: 4, height: 4)
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

    // MARK: - Today's Focus Section
    private var todaysFocusSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundStyle(DS.ColorToken.accent)
                Text("Today's Focus")
                    .font(.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)
            }
            
            if let focusInsight = vm.insights.first(where: { $0.type == .behavior || $0.severity == .warning }) {
                HStack(alignment: .top, spacing: DS.Spacing.s) {
                    Image(systemName: "lightbulb.fill")
                        .font(.subheadline)
                        .foregroundStyle(DS.ColorToken.warning)
                    Text(focusInsight.message)
                        .font(.subheadline)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(DS.Spacing.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DS.ColorToken.warning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                        .stroke(DS.ColorToken.warning.opacity(0.3), lineWidth: 1)
                )
            } else {
                InfoBanner(text: "Read-only journal. Sync is delayed; it may take a few minutes. Metrics are based on realized trades.")
            }
        }
    }
    
    // MARK: - Snapshot Section
    private func snapshotSection(summary: AnalyticsSummary) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader(title: "Snapshot", icon: "chart.bar.fill")
            
            // Account Health - Primary Card
            accountHealthCard()
            
            // Secondary Metrics Grid
            let cols = [GridItem(.flexible(), spacing: DS.Spacing.m), GridItem(.flexible(), spacing: DS.Spacing.m)]
            LazyVGrid(columns: cols, spacing: DS.Spacing.m) {
                equityCard(summary: summary)
                dailyPnLCard(summary: summary)
                drawdownCard(summary: summary)
                winRateCard(summary: summary)
            }
        }
    }
    
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
    
    private func accountHealthCard() -> some View {
        let healthStatus = vm.accountHealth
        
        return VStack(alignment: .leading, spacing: DS.Spacing.m) {
            HStack {
                Image(systemName: healthStatus.icon)
                    .font(.title2)
                    .foregroundStyle(healthColor(healthStatus))
                VStack(alignment: .leading, spacing: 4) {
                    Text(healthStatus.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(DS.ColorToken.textPrimary)
                    Text(healthStatus.message)
                        .font(.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
                Spacer()
            }
            
            if let ddPercent = healthStatus.drawdownPercent {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Max Drawdown")
                            .font(.caption)
                            .foregroundStyle(DS.ColorToken.textSecondary)
                        Spacer()
                        Text(String(format: "%.1f%%", ddPercent))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(healthColor(healthStatus))
                    }
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(DS.ColorToken.cardElevated)
                                .frame(height: 6)
                                .clipShape(Capsule())
                            Rectangle()
                                .fill(healthColor(healthStatus))
                                .frame(width: geometry.size.width * min(ddPercent / 10.0, 1.0), height: 6)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(height: 6)
                    HStack {
                        Text("Limit: 10%")
                            .font(.caption2)
                            .foregroundStyle(DS.ColorToken.textTertiary)
                        Spacer()
                    }
                }
            }
        }
        .padding(DS.Spacing.l)
        .card(color: healthColor(healthStatus))
    }
    
    private func healthColor(_ status: DashboardViewModel.AccountHealthStatus) -> Color {
        switch status {
        case .unknown: return DS.ColorToken.textTertiary
        case .healthy: return DS.ColorToken.success
        case .warning: return DS.ColorToken.warning
        case .risk: return DS.ColorToken.danger
        }
    }
    
    private func equityCard(summary: AnalyticsSummary) -> some View {
        let equity = summary.equity ?? Decimal(10000)
        let startingEquity = Decimal(10000)
        let change = (equity as NSDecimalNumber).doubleValue - (startingEquity as NSDecimalNumber).doubleValue
        let changePercent = change / (startingEquity as NSDecimalNumber).doubleValue * 100
        
        return MetricCard(
            title: "Equity",
            value: formatDecimal(equity),
            change: String(format: "%+.1f%% this week", changePercent),
            icon: "chart.line.uptrend.xyaxis",
            color: DS.ColorToken.metricPurple
        )
    }
    
    private func dailyPnLCard(summary: AnalyticsSummary) -> some View {
        let dailyPnL = summary.dailyPnL ?? 0
        let equity = summary.equity ?? Decimal(10000)
        let pnlPercent = (dailyPnL as NSDecimalNumber).doubleValue / (equity as NSDecimalNumber).doubleValue * 100
        
        return MetricCard(
            title: "Daily P/L",
            value: formatDecimal(dailyPnL),
            change: String(format: "%.2f%% of balance", pnlPercent),
            icon: "calendar",
            color: dailyPnL >= 0 ? DS.ColorToken.metricGreen : DS.ColorToken.metricPink
        )
    }
    
    private func drawdownCard(summary: AnalyticsSummary) -> some View {
        let dd = summary.maxDrawdown
        let startingEquity = Decimal(10000)
        let ddPercent = (dd as NSDecimalNumber).doubleValue / (startingEquity as NSDecimalNumber).doubleValue * 100
        let riskColor: Color = ddPercent < 5 ? DS.ColorToken.metricTeal : (ddPercent < 10 ? DS.ColorToken.metricOrange : DS.ColorToken.metricPink)
        
        return VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(riskColor)
                    .frame(width: 40, height: 40)
                    .background(riskColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDecimal(dd))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DS.ColorToken.textPrimary)
                
                Text("Drawdown")
                    .font(.subheadline)
                    .foregroundStyle(DS.ColorToken.textSecondary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(DS.ColorToken.cardElevated)
                            .frame(height: 4)
                            .clipShape(Capsule())
                        Rectangle()
                            .fill(riskColor)
                            .frame(width: geometry.size.width * min(ddPercent / 10.0, 1.0), height: 4)
                            .clipShape(Capsule())
                    }
                }
                .frame(height: 4)
                
                Text(String(format: "%.1f%%", ddPercent))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(riskColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(color: riskColor)
    }
    
    private func winRateCard(summary: AnalyticsSummary) -> some View {
        MetricCard(
            title: "Win Rate",
            value: String(format: "%.1f%%", summary.winRate * 100),
            change: nil,
            icon: "target",
            color: DS.ColorToken.metricPurple
        )
    }
    
    // MARK: - Performance Section
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader(title: "Performance", icon: "chart.line.uptrend.xyaxis")
            
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
            HStack {
                Text("Equity Curve")
                    .font(.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Spacer()
                if let selected = selectedEquityPoint {
                    VStack(alignment: .trailing) {
                        Text(String(format: "$%.2f", selected.equity))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(DS.ColorToken.metricPurple)
                        Text(selected.day)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.l)
            
            Chart(series.points) { p in
                LineMark(
                    x: .value("Day", p.dayISO),
                    y: .value("Equity", (p.equity as NSDecimalNumber).doubleValue)
                )
                .foregroundStyle(DS.ColorToken.metricPurple)
                .interpolationMethod(.catmullRom)
                
                if let selected = selectedEquityPoint, selected.day == p.dayISO {
                    RuleMark(x: .value("Day", selected.day))
                        .foregroundStyle(DS.ColorToken.metricPurple.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        
                    PointMark(
                        x: .value("Day", selected.day),
                        y: .value("Equity", selected.equity)
                    )
                    .foregroundStyle(DS.ColorToken.metricPurple)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let origin = geometry[proxy.plotAreaFrame].origin
                                    let location = CGPoint(
                                        x: value.location.x - origin.x,
                                        y: value.location.y - origin.y
                                    )
                                    guard let day = proxy.value(atX: location.x, as: String.self) else { return }
                                    
                                    if let point = series.points.first(where: { $0.dayISO == day }) {
                                        selectedEquityPoint = (point.dayISO, (point.equity as NSDecimalNumber).doubleValue)
                                    }
                                }
                                .onEnded { _ in
                                    selectedEquityPoint = nil
                                }
                        )
                }
            }
            .frame(height: 200)
            .padding(DS.Spacing.l)
            .card()
        }
    }
    
    private func dailyPnLChart(series: PnlSeries) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            HStack {
                Text("Daily P/L")
                    .font(.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Spacer()
                if let selected = selectedPnlPoint {
                    VStack(alignment: .trailing) {
                        Text(String(format: "%@$%.2f", selected.pnl >= 0 ? "+" : "", selected.pnl))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(selected.pnl >= 0 ? DS.ColorToken.success : DS.ColorToken.danger)
                        Text(selected.day)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.l)
            
            Chart(series.points) { p in
                BarMark(
                    x: .value("Day", p.dayISO),
                    y: .value("P/L", (p.pnl as NSDecimalNumber).doubleValue)
                )
                .foregroundStyle((p.pnl as NSDecimalNumber).doubleValue >= 0 ? DS.ColorToken.success : DS.ColorToken.danger)
                .cornerRadius(4)
                
                if let selected = selectedPnlPoint, selected.day == p.dayISO {
                    RuleMark(x: .value("Day", selected.day))
                        .foregroundStyle(Color.primary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let origin = geometry[proxy.plotAreaFrame].origin
                                    let location = CGPoint(
                                        x: value.location.x - origin.x,
                                        y: value.location.y - origin.y
                                    )
                                    guard let day = proxy.value(atX: location.x, as: String.self) else { return }
                                    
                                    if let point = series.points.first(where: { $0.dayISO == day }) {
                                        selectedPnlPoint = (point.dayISO, (point.pnl as NSDecimalNumber).doubleValue)
                                    }
                                }
                                .onEnded { _ in
                                    selectedPnlPoint = nil
                                }
                        )
                }
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
            sectionHeader(title: "Risk", icon: "exclamationmark.triangle.fill")
            
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
    
    // MARK: - Activity Section
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader(title: "Activity", icon: "clock.fill")
            
            // Open Trades
            if !vm.openTrades.isEmpty {
                openTradesSection
                
                // Floating PnL
                floatingPnLSection
            } else {
                Text("No open trades")
                    .font(.subheadline)
                    .foregroundStyle(DS.ColorToken.textSecondary)
                    .padding(DS.Spacing.l)
                    .frame(maxWidth: .infinity)
                    .card()
            }
        }
    }
    
    private var openTradesSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Open Trades")
                .font(.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)
                .padding(.horizontal, DS.Spacing.l)
            
            VStack(spacing: 0) {
                ForEach(Array(vm.openTrades.enumerated()), id: \.element.id) { index, trade in
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
                            Text("OPEN")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DS.ColorToken.info)
                        }
                        .padding(DS.Spacing.l)
                    }
                    .buttonStyle(.plain)
                    
                    if index < vm.openTrades.count - 1 {
                        Divider()
                            .background(DS.ColorToken.border)
                            .padding(.leading, DS.Spacing.l)
                    }
                }
            }
            .card()
        }
    }
    
    private var floatingPnLSection: some View {
        let floatingPnL = vm.openTrades.compactMap { $0.profit }.reduce(Decimal(0), +)
        return MetricCard(
            title: "Floating P/L",
            value: formatDecimal(floatingPnL),
            change: floatingPnL >= 0 ? "+\(formatDecimal(floatingPnL))" : formatDecimal(floatingPnL),
            icon: "chart.line.uptrend.xyaxis.circle.fill",
            color: floatingPnL >= 0 ? DS.ColorToken.metricGreen : DS.ColorToken.metricPink
        )
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader(title: "Insights", icon: "lightbulb.fill")
            
            if vm.insights.isEmpty {
                InfoBanner(text: "Read-only journal. Sync is delayed; it may take a few minutes. Metrics are based on realized trades.")
            } else {
                VStack(spacing: DS.Spacing.s) {
                    ForEach(vm.insights) { insight in
                        insightCard(insight: insight)
                    }
                }
            }
        }
    }
    
    private func insightCard(insight: Insight) -> some View {
        HStack(alignment: .center, spacing: DS.Spacing.s) {
            // Label badge
            Text(insightLabel(insight.type))
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(labelColor(insight.type))
                .clipShape(Capsule())
            
            Image(systemName: iconForInsight(insight))
                .foregroundStyle(colorForInsight(insight))
                .font(.caption)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.m)
        .padding(.vertical, DS.Spacing.s)
        .background(colorForInsight(insight).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                .stroke(colorForInsight(insight).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func insightLabel(_ type: InsightType) -> String {
        switch type {
        case .timeBased: return "⏱ TIME"
        case .pairBased: return "📊 PAIR"
        case .behavior: return "🧠 BEHAVIOR"
        }
    }
    
    private func labelColor(_ type: InsightType) -> Color {
        switch type {
        case .timeBased: return DS.ColorToken.info
        case .pairBased: return DS.ColorToken.metricPurple
        case .behavior: return DS.ColorToken.warning
        }
    }
    
    private func iconForInsight(_ insight: Insight) -> String {
        switch insight.type {
        case .timeBased: return "clock.fill"
        case .pairBased: return "chart.bar.fill"
        case .behavior: return "brain.head.profile"
        }
    }
    
    private func colorForInsight(_ insight: Insight) -> Color {
        switch insight.severity {
        case .info: return DS.ColorToken.info
        case .warning: return DS.ColorToken.warning
        case .critical: return DS.ColorToken.danger
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


