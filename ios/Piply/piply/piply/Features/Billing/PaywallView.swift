import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let message: String
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("Upgrade to Pro")
                    .font(.title2.weight(.semibold))

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                NavigationLink {
                    PricingView(env: env)
                } label: {
                    Text("See pricing")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(DS.ColorToken.accent)
                .padding(.top, 8)

                SecondaryButton(title: "Not now") { dismiss() }
            }
            .padding(24)
            .background(DS.ColorToken.background)
            .navigationTitle("Paywall")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


