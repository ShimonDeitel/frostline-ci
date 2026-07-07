import Foundation
import SwiftUI

@MainActor
final class FrostlineStore: ObservableObject {
    @Published private(set) var entries: [ColdEntry] = []
    @AppStorage("frostline_reminder_enabled") var reminderEnabled: Bool = false
    @AppStorage("frostline_haptics_enabled") var hapticsEnabled: Bool = true

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("frostline_entries.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
    }

    private var calendar: Calendar { .current }

    func entry(on day: Date) -> ColdEntry? {
        let target = StreakMath.startOfDay(day, calendar: calendar)
        return entries.first { StreakMath.startOfDay($0.date, calendar: calendar) == target }
    }

    /// Logs today's entry. If an entry already exists for today, it's replaced
    /// (not duplicated) so marking today twice never double counts.
    @discardableResult
    func logToday(tookShower: Bool, durationSeconds: Int?, note: String, referenceDate: Date = Date()) -> Milestone? {
        let today = StreakMath.startOfDay(referenceDate, calendar: calendar)
        let oldStreak = currentStreak(referenceDate: referenceDate)

        if let idx = entries.firstIndex(where: { StreakMath.startOfDay($0.date, calendar: calendar) == today }) {
            entries[idx].tookShower = tookShower
            entries[idx].durationSeconds = durationSeconds
            entries[idx].note = note
        } else {
            entries.append(ColdEntry(date: today, tookShower: tookShower, durationSeconds: durationSeconds, note: note))
        }
        save()

        let newStreak = currentStreak(referenceDate: referenceDate)
        return StreakMath.newlyReachedMilestone(oldStreak: oldStreak, newStreak: newStreak)
    }

    func deleteEntry(_ id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    // MARK: - Derived

    func currentStreak(referenceDate: Date = Date()) -> Int {
        StreakMath.currentStreak(entries: entries, referenceDate: referenceDate, calendar: calendar)
    }

    var longestStreak: Int {
        StreakMath.longestStreak(entries: entries, calendar: calendar)
    }

    var totalColdShowers: Int {
        StreakMath.totalColdShowers(entries: entries)
    }

    var averageDurationSeconds: Double {
        StreakMath.averageDurationSeconds(entries: entries)
    }

    /// Entries sorted most-recent first.
    var sortedEntries: [ColdEntry] {
        entries.sorted { $0.date > $1.date }
    }

    /// Free-tier visible history: last 7 days only.
    var recentEntries: [ColdEntry] {
        Array(sortedEntries.prefix(7))
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([ColdEntry].self, from: data) {
            entries = decoded
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
