import SwiftUI

@main
struct PiplyApp: App {
    @StateObject private var env = AppEnvironment(api: MockAPIClient())

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(env)
        }
    }
}


