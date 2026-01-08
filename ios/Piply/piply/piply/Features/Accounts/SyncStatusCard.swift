import SwiftUI

struct SyncStatusCard: View {
    let account: TradingAccount
    var onSync: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(account.broker) • \(account.accountId)")
                    .font(.headline)
                Spacer()
                StatusBadge(status: account.status)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Last attempt")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(format(account.lastAttemptedSyncAt))
                }
                .font(.subheadline)

                HStack {
                    Text("Last success")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(format(account.lastSuccessfulSyncAt))
                }
                .font(.subheadline)
            }

            if account.status == .failed, let msg = account.lastErrorMessage {
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(DS.ColorToken.danger)
            }

            PrimaryButton(title: "Sync now", action: onSync)
        }
        .card(elevated: true)
    }

    private func format(_ date: Date?) -> String {
        guard let date else { return "—" }
        return DateFormatters.shortDateTime.string(from: date)
    }
}


