import SwiftUI

struct AccountsView: View {
    let env: AppEnvironment
    @StateObject private var vm: AccountsViewModel

    @State private var showAdd = false

    init(env: AppEnvironment) {
        self.env = env
        _vm = StateObject(wrappedValue: AccountsViewModel(env: env))
    }

    var body: some View {
        content
            .task { await vm.refresh() }
            .sheet(isPresented: $showAdd) {
                AddTradingAccountView { broker, server, accountId, password in
                    await vm.createAccount(broker: broker, server: server, accountId: accountId, password: password)
                }
            }
            .sheet(isPresented: $vm.showPaywall) {
                PaywallView(message: vm.paywallMessage ?? "Upgrade to Pro to unlock more accounts.")
            }
    }
    
    private func syncAllAccounts() async {
        for account in vm.accounts {
            await vm.triggerSync(accountId: account.id)
        }
    }

    private var content: some View {
        List {
            Section {
                InfoBanner(text: "Accounts use read-only access. We never place trades. Sync is delayed and may take a few minutes.")
            }

            if let error = vm.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(DS.ColorToken.danger)
                }
            }

            if vm.accounts.isEmpty {
                Section {
                    EmptyStateView(
                        title: "No accounts",
                        message: "Connect your trading account to start syncing trades and see your dashboard.",
                        systemImage: "link",
                        actionTitle: "Add account",
                        action: { showAdd = true }
                    )
                }
            } else {
                Section("Connected accounts") {
                    ForEach(vm.accounts) { acc in
                        SyncStatusCard(account: acc) {
                            Task { await vm.triggerSync(accountId: acc.id) }
                        }
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 6)
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            let id = vm.accounts[idx].id
                            Task { await vm.deleteAccount(id: id) }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            if !vm.accounts.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await syncAllAccounts() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .refreshable { await vm.refresh() }
        .background(DS.ColorToken.background)
    }
}


