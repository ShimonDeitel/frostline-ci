import SwiftUI

struct StreakView: View {
    @EnvironmentObject private var store: FrostlineStore
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var sheetMode: HomeSheetMode?
    @State private var isShattering = false
    @State private var breakMessage: String?

    private var todayEntry: ColdEntry? {
        store.entry(on: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FrostTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        header

                        IceCrystalView(streak: store.currentStreak(), isShattering: isShattering)
                            .frame(width: 220, height: 220)
                            .padding(.top, 8)

                        VStack(spacing: 6) {
                            Text("\(store.currentStreak())")
                                .font(FrostTheme.displayFont)
                                .foregroundStyle(FrostTheme.cyan)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.currentStreak())
                            Text(store.currentStreak() == 1 ? "day streak" : "day streak")
                                .font(.subheadline)
                                .foregroundStyle(FrostTheme.inkFaded)
                        }

                        if let breakMessage {
                            Text(breakMessage)
                                .font(.subheadline)
                                .foregroundStyle(FrostTheme.warning)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .transition(.opacity)
                        }

                        todayStatusCard

                        recentHistoryCard

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                .dismissKeyboardOnTap()

                VStack {
                    Spacer()
                    logButton
                        .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $sheetMode) { mode in
                switch mode {
                case .logToday:
                    LogTodaySheet(existing: todayEntry) { milestone in
                        handlePostSave(milestone: milestone)
                    }
                    .environmentObject(store)
                case .history:
                    HistoryView()
                        .environmentObject(store)
                        .environmentObject(purchases)
                case .settings:
                    SettingsView()
                        .environmentObject(store)
                        .environmentObject(purchases)
                case .paywall:
                    PaywallView()
                        .environmentObject(purchases)
                }
            }
        }
        .tint(FrostTheme.cyan)
    }

    private func handlePostSave(milestone: Milestone?) {
        if let entry = todayEntry, !entry.tookShower {
            withAnimation { isShattering = true }
            breakMessage = "Your streak reset. Every cold shower still counts."
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation { isShattering = false }
            }
        } else {
            breakMessage = nil
            if let milestone {
                Haptics.success()
                breakMessage = "Milestone reached: \(milestone.label)!"
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Frostline")
                    .font(FrostTheme.titleFont)
                    .foregroundStyle(FrostTheme.ink)
                Text(Date(), format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(FrostTheme.inkFaded)
            }
            Spacer()
            Button {
                sheetMode = .settings
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(FrostTheme.ink)
                    .padding(10)
                    .background(Circle().fill(FrostTheme.surfaceRaised))
            }
            .accessibilityIdentifier("settingsButton")
        }
        .padding(.top, 8)
    }

    private var todayStatusCard: some View {
        HStack {
            Image(systemName: todayEntry?.tookShower == true ? "checkmark.circle.fill" : "circle.dashed")
                .font(.system(size: 20))
                .foregroundStyle(todayEntry?.tookShower == true ? FrostTheme.cyan : FrostTheme.inkFaded)
            VStack(alignment: .leading, spacing: 2) {
                Text(todayStatusText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(FrostTheme.ink)
                if let seconds = todayEntry?.durationSeconds {
                    Text(formatDuration(seconds))
                        .font(.caption)
                        .foregroundStyle(FrostTheme.inkFaded)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(FrostTheme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FrostTheme.cardBorder, lineWidth: 1))
        .accessibilityIdentifier("todayStatusCard")
    }

    private var todayStatusText: String {
        guard let todayEntry else { return "Not logged yet today" }
        return todayEntry.tookShower ? "Cold shower logged today" : "Marked as skipped today"
    }

    private var recentHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Days")
                    .font(FrostTheme.headlineFont)
                    .foregroundStyle(FrostTheme.ink)
                Spacer()
                Button {
                    sheetMode = purchases.isPro ? .history : .paywall
                } label: {
                    Text(purchases.isPro ? "Full History" : "Full History (Pro)")
                        .font(.caption)
                        .foregroundStyle(FrostTheme.cyan)
                }
                .accessibilityIdentifier("fullHistoryButton")
            }

            if store.recentEntries.isEmpty {
                Text("Nothing logged yet. Tap Log Today to begin your streak.")
                    .font(.subheadline)
                    .foregroundStyle(FrostTheme.inkFaded)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(store.recentEntries.prefix(7)) { entry in
                    HStack {
                        Image(systemName: entry.tookShower ? "snowflake" : "xmark.circle")
                            .foregroundStyle(entry.tookShower ? FrostTheme.cyan : FrostTheme.danger)
                            .frame(width: 24)
                        Text(entry.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                            .font(.caption)
                            .foregroundStyle(FrostTheme.ink)
                        Spacer()
                        if let seconds = entry.durationSeconds {
                            Text(formatDuration(seconds))
                                .font(.caption2)
                                .foregroundStyle(FrostTheme.inkFaded)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(FrostTheme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FrostTheme.cardBorder, lineWidth: 1))
    }

    private var logButton: some View {
        Button {
            sheetMode = .logToday
        } label: {
            Label("Log Today", systemImage: "snowflake")
                .font(.headline)
                .foregroundStyle(FrostTheme.backdrop)
                .padding(.vertical, 16)
                .padding(.horizontal, 28)
                .background(Capsule().fill(FrostTheme.cyan))
        }
        .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
        .accessibilityIdentifier("logTodayButton")
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
}

#Preview {
    StreakView()
        .environmentObject(FrostlineStore())
        .environmentObject(PurchaseManager())
}
