import SwiftUI

/// Pro-gated: full history/calendar + stats (average duration, longest streak, total cold showers).
struct HistoryView: View {
    @EnvironmentObject private var store: FrostlineStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FrostTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        statsGrid

                        VStack(alignment: .leading, spacing: 10) {
                            Text("All Entries")
                                .font(FrostTheme.headlineFont)
                                .foregroundStyle(FrostTheme.ink)

                            if store.sortedEntries.isEmpty {
                                Text("No entries logged yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(FrostTheme.inkFaded)
                            } else {
                                ForEach(store.sortedEntries) { entry in
                                    HStack {
                                        Image(systemName: entry.tookShower ? "snowflake" : "xmark.circle")
                                            .foregroundStyle(entry.tookShower ? FrostTheme.cyan : FrostTheme.danger)
                                            .frame(width: 24)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.date, format: .dateTime.weekday(.wide).month(.abbreviated).day().year())
                                                .font(.caption)
                                                .foregroundStyle(FrostTheme.ink)
                                            if !entry.note.isEmpty {
                                                Text(entry.note)
                                                    .font(.caption2)
                                                    .foregroundStyle(FrostTheme.inkFaded)
                                            }
                                        }
                                        Spacer()
                                        if let seconds = entry.durationSeconds {
                                            Text("\(seconds / 60)m \(seconds % 60)s")
                                                .font(.caption2)
                                                .foregroundStyle(FrostTheme.inkFaded)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    Divider().overlay(FrostTheme.rule)
                                }
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(FrostTheme.surface))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Full History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(title: "Longest Streak", value: "\(store.longestStreak)", suffix: "days")
            statCard(title: "Total Cold Showers", value: "\(store.totalColdShowers)", suffix: "")
            statCard(title: "Average Duration", value: formattedAverage, suffix: "")
        }
    }

    private var formattedAverage: String {
        let avg = Int(store.averageDurationSeconds.rounded())
        guard avg > 0 else { return "—" }
        return "\(avg / 60)m \(avg % 60)s"
    }

    private func statCard(title: String, value: String, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .tracking(0.6)
                .foregroundStyle(FrostTheme.inkFaded)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(FrostTheme.cyan)
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.caption)
                        .foregroundStyle(FrostTheme.inkFaded)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(FrostTheme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(FrostTheme.cardBorder, lineWidth: 1))
    }
}

#Preview {
    HistoryView()
        .environmentObject(FrostlineStore())
        .environmentObject(PurchaseManager())
}
