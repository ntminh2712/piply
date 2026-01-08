import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vm = AuthViewModel()

    let onSwitchToSignup: () -> Void

    init(onSwitchToSignup: @escaping () -> Void) {
        self.onSwitchToSignup = onSwitchToSignup
    }

    var body: some View {
        content
    }

    private var content: some View {
        VStack(spacing: 16) {
            InfoBanner(text: "Read-only: the app cannot place trades or change your account. Sync is delayed and may take a few minutes.")

            Form {
                Section("Email") {
                    TextField("you@example.com", text: $vm.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
                Section("Password") {
                    SecureField("Password", text: $vm.password)
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
            .scrollContentBackground(.hidden)

            PrimaryButton(title: "Login", isLoading: vm.isLoading) {
                Task {
                    let session = await vm.submit {
                        try await env.api.login(email: vm.email, password: vm.password)
                    }
                    if let session { env.setSession(session) }
                }
            }
            .padding(.horizontal)

            Button("Don’t have an account? Sign up") {
                onSwitchToSignup()
            }
            .font(.subheadline)

            Spacer(minLength: 0)
        }
        .padding(.top, 12)
    }
}


