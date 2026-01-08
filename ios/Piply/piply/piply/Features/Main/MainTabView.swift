import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        TabView {
            NavigationStack { DashboardView(env: env) }
                .tabItem { Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis") }

            NavigationStack { AnalyticsView(env: env) }
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }

            NavigationStack { TradesView(env: env) }
                .tabItem { Label("Trades", systemImage: "list.bullet.rectangle") }

            NavigationStack { AccountsView(env: env) }
                .tabItem { Label("Accounts", systemImage: "link") }

            NavigationStack { SettingsView(env: env) }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(DS.ColorToken.accent)
    }
}


