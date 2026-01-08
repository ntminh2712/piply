import SwiftUI

struct SignupView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vm = AuthViewModel()

    let onSwitchToLogin: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            InfoBanner(text: "Read-only: the app cannot place trades or change your account. Sync is delayed and may take a few minutes.")

            Form {
                Section("Email") {
                    TextField("you@example.com", text: $vm.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
                Section("Password") {
                    SecureField("Password (min 6 chars)", text: $vm.password)
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
            .scrollContentBackground(.hidden)

            PrimaryButton(title: "Create account", isLoading: vm.isLoading) {
                Task {
                    let session = await vm.submit {
                        try await env.api.signup(email: vm.email, password: vm.password)
                    }
                    if let session { env.setSession(session) }
                }
            }
            .padding(.horizontal)

            Button("Already have an account? Login") {
                onSwitchToLogin()
            }
            .font(.subheadline)

            Spacer(minLength: 0)
        }
        .padding(.top, 12)
    }
}


