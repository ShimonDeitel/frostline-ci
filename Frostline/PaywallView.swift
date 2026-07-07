import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    private let features: [(String, String)] = [
        ("calendar", "Full history and calendar, not just the last 7 days"),
        ("chart.bar.fill", "Average duration, longest streak, and total showers"),
        ("snowflake", "See every milestone crystal you've ever grown"),
        ("bell.badge.fill", "Priority reminder customization")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                FrostTheme.backdrop.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Image(systemName: "snowflake")
                            .font(.system(size: 40))
                            .foregroundStyle(FrostTheme.cyan)
                            .padding(.top, 20)
                        Text("Frostline Pro")
                            .font(FrostTheme.displayFont)
                            .foregroundStyle(FrostTheme.ink)
                        Text("For the fully-tracked cold streak.")
                            .font(.subheadline)
                            .foregroundStyle(FrostTheme.inkFaded)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(features, id: \.1) { feature in
                            HStack(spacing: 14) {
                                Image(systemName: feature.0)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(FrostTheme.cyan)
                                    .frame(width: 26)
                                Text(feature.1)
                                    .font(.subheadline)
                                    .foregroundStyle(FrostTheme.ink)
                                Spacer()
                            }
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(FrostTheme.surface))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(FrostTheme.cardBorder, lineWidth: 1))

                    Spacer()

                    Button {
                        Task { await purchases.purchase() }
                    } label: {
                        VStack(spacing: 2) {
                            Text("Start Frostline Pro")
                                .font(.headline)
                            Text(purchases.product?.displayPrice.appending("/month") ?? "$0.99/month")
                                .font(.caption)
                                .opacity(0.85)
                        }
                        .foregroundStyle(FrostTheme.backdrop)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(FrostTheme.cyan))
                    }
                    .accessibilityIdentifier("startProButton")

                    Button("Restore Purchases") {
                        Task { await purchases.restore() }
                    }
                    .font(.footnote)
                    .foregroundStyle(FrostTheme.inkFaded)
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: purchases.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }
}

#Preview {
    PaywallView().environmentObject(PurchaseManager())
}
