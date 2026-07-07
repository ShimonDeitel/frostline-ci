import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: FrostlineStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false

    private let privacyURL = URL(string: "https://shimondeitel.github.io/frostline-site/privacy.html")!
    private let termsURL = URL(string: "https://shimondeitel.github.io/frostline-site/terms.html")!
    private let supportURL = URL(string: "https://shimondeitel.github.io/frostline-site/support.html")!

    var body: some View {
        NavigationStack {
            ZStack {
                FrostTheme.backdrop.ignoresSafeArea()

                Form {
                    Section("Reminders") {
                        Toggle("Daily reminder", isOn: $store.reminderEnabled)
                            .accessibilityIdentifier("reminderToggle")
                        Toggle("Haptics", isOn: $store.hapticsEnabled)
                            .accessibilityIdentifier("hapticsToggle")
                            .onChange(of: store.hapticsEnabled) { _, newValue in
                                Haptics.enabled = newValue
                            }
                    }

                    Section("Membership") {
                        if purchases.isPro {
                            HStack {
                                Text("Frostline Pro")
                                Spacer()
                                Text("Active")
                                    .foregroundStyle(FrostTheme.cyan)
                                    .fontWeight(.semibold)
                            }
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                Text("Upgrade to Frostline Pro")
                            }
                            .accessibilityIdentifier("upgradeButton")
                        }

                        Button("Restore Purchases") {
                            Task { await purchases.restore() }
                        }
                        .accessibilityIdentifier("restorePurchasesButton")
                    }

                    Section("About") {
                        Link("Privacy Policy", destination: privacyURL)
                        Link("Terms of Use", destination: termsURL)
                        Link("Contact Support", destination: supportURL)
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(FrostTheme.inkFaded)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .dismissKeyboardOnTap()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(purchases)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(FrostlineStore())
        .environmentObject(PurchaseManager())
}
