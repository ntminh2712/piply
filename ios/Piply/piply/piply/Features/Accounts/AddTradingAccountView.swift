import SwiftUI

struct AddTradingAccountView: View {
    @Environment(\.dismiss) private var dismiss

    let onCreate: (_ broker: String, _ server: String, _ accountId: String, _ password: String) async -> Bool

    @State private var broker = ""
    @State private var server = ""
    @State private var accountId = ""
    @State private var password = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    InfoBanner(text: "Read-only: the app cannot place trades or change your account. Sync is delayed; it may take a few minutes.")
                }

                Section("Account") {
                    TextField("Broker", text: $broker)
                    TextField("Server", text: $server)
                    TextField("Account ID", text: $accountId)
                        .textInputAutocapitalization(.never)
                }

                Section("Read-only password") {
                    SecureField("Password", text: $password)
                }
            }
            .navigationTitle("Add account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack {
                    PrimaryButton(title: "Connect", isLoading: isSubmitting) {
                        Task {
                            isSubmitting = true
                            let ok = await onCreate(broker, server, accountId, password)
                            isSubmitting = false
                            if ok { dismiss() }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
}


