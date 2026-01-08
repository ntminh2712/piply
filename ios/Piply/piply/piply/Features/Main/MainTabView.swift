import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject private var env: AppEnvironment

    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { DashboardView(env: env) }
                .tabItem { 
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)

            NavigationStack { AnalyticsView(env: env) }
                .tabItem { 
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(1)

            NavigationStack { TradesView(env: env) }
                .tabItem { 
                    Label("Trades", systemImage: "list.bullet.rectangle")
                }
                .tag(2)

            NavigationStack { AccountsView(env: env) }
                .tabItem { 
                    Label("Accounts", systemImage: "link")
                }
                .tag(3)

            NavigationStack { SettingsView(env: env) }
                .tabItem { 
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(4)
        }
        .tint(DS.ColorToken.accent)
        .onAppear {
            // Make Dashboard tab more prominent
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(DS.ColorToken.card)
            
            // Normal state - reduced opacity for non-selected tabs
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(DS.ColorToken.textSecondary).withAlphaComponent(0.6)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(DS.ColorToken.textSecondary).withAlphaComponent(0.6)]
            
            // Selected state - full opacity for selected tab
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(DS.ColorToken.accent)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(DS.ColorToken.accent)]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}


