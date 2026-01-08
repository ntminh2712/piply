import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                Text(title)
                    .font(.headline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(DS.ColorToken.accent)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
        .disabled(isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(title) { action() }
            .buttonStyle(.bordered)
    }
}

struct InfoBanner: View {
    let text: String
    var systemImage: String = "info.circle"

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.s) {
            Image(systemName: systemImage)
                .foregroundStyle(DS.ColorToken.info)
            Text(text)
                .font(.subheadline)
            Spacer(minLength: 0)
        }
        .card()
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage: String = "tray"
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 260)
            }
        }
        .padding(24)
    }
}

struct ErrorView: View {
    let message: String
    var actionTitle: String = "Try again"
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(DS.ColorToken.warning)
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let action {
                SecondaryButton(title: actionTitle, action: action)
            }
        }
        .card()
    }
}

struct StatusBadge: View {
    let status: TradingAccountStatus

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch status {
        case .pending: return "Pending"
        case .syncing: return "Syncing"
        case .synced: return "Synced"
        case .failed: return "Failed"
        }
    }

    private var color: Color {
        switch status {
        case .pending: return .gray
        case .syncing: return DS.ColorToken.info
        case .synced: return DS.ColorToken.success
        case .failed: return DS.ColorToken.danger
        }
    }
}


