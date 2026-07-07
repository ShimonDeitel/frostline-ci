import Foundation

/// A single day's cold-exposure log entry.
struct ColdEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date          // normalized to start-of-day
    var tookShower: Bool
    var durationSeconds: Int?
    var note: String

    init(id: UUID = UUID(), date: Date, tookShower: Bool, durationSeconds: Int? = nil, note: String = "") {
        self.id = id
        self.date = date
        self.tookShower = tookShower
        self.durationSeconds = durationSeconds
        self.note = note
    }
}

/// Milestone thresholds (consecutive-day streak counts) that grow the ice crystal.
enum Milestone: Int, CaseIterable, Identifiable {
    case three = 3
    case seven = 7
    case fourteen = 14
    case thirty = 30
    case sixty = 60
    case oneHundred = 100

    var id: Int { rawValue }

    var label: String {
        "\(rawValue)-day streak"
    }
}

/// Pure calculation engine for streaks, kept free of I/O so it's directly unit testable.
enum StreakMath {

    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Current streak: count consecutive days ending at (and including) `referenceDate`
    /// where an entry exists with `tookShower == true`, walking backward day by day.
    /// A missing day OR a day explicitly marked `tookShower == false` breaks the streak.
    static func currentStreak(entries: [ColdEntry], referenceDate: Date, calendar: Calendar = .current) -> Int {
        let byDay = Dictionary(uniqueKeysWithValues: entries.map { (startOfDay($0.date, calendar: calendar), $0) })
        var streak = 0
        var cursor = startOfDay(referenceDate, calendar: calendar)
        while let entry = byDay[cursor], entry.tookShower {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Longest streak ever achieved across all logged entries.
    static func longestStreak(entries: [ColdEntry], calendar: Calendar = .current) -> Int {
        guard !entries.isEmpty else { return 0 }
        let sortedDays = Set(entries.filter { $0.tookShower }.map { startOfDay($0.date, calendar: calendar) }).sorted()
        guard !sortedDays.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        for i in 1..<sortedDays.count {
            let diff = calendar.dateComponents([.day], from: sortedDays[i - 1], to: sortedDays[i]).day ?? 0
            if diff == 1 {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
        }
        return longest
    }

    /// Total number of days where a cold shower was actually taken.
    static func totalColdShowers(entries: [ColdEntry]) -> Int {
        entries.filter { $0.tookShower }.count
    }

    /// Average duration in seconds across entries that both took the shower and logged a duration.
    static func averageDurationSeconds(entries: [ColdEntry]) -> Double {
        let durations = entries.filter { $0.tookShower }.compactMap { $0.durationSeconds }
        guard !durations.isEmpty else { return 0 }
        return Double(durations.reduce(0, +)) / Double(durations.count)
    }

    /// Highest milestone reached at or below the given streak count.
    static func highestMilestone(for streak: Int) -> Milestone? {
        Milestone.allCases.filter { $0.rawValue <= streak }.max { $0.rawValue < $1.rawValue }
    }

    /// Whether crossing from `oldStreak` to `newStreak` just hit a new milestone.
    static func newlyReachedMilestone(oldStreak: Int, newStreak: Int) -> Milestone? {
        Milestone.allCases.first { newStreak >= $0.rawValue && oldStreak < $0.rawValue }
    }
}
