import SwiftUI

struct AuthFlowView: View {
    @State private var mode: Mode = .login

    enum Mode {
        case login
        case signup
    }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .login:
                    LoginView(onSwitchToSignup: { mode = .signup })
                case .signup:
                    SignupView(onSwitchToLogin: { mode = .login })
                }
            }
            .navigationTitle(mode == .login ? "Login" : "Sign up")
        }
    }
}


