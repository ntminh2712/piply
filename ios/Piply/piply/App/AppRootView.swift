import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        Group {
            if env.isLoggedIn {
                MainTabView()
            } else {
                AuthFlowView()
            }
        }
    }
}


