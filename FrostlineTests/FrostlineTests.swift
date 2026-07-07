import XCTest
@testable import Frostline

final class FrostlineTests: XCTestCase {

    private var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func fixedDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return utcCalendar.date(from: components)!
    }

    // MARK: - Current streak

    func testCurrentStreakZeroWhenNoEntries() {
        let streak = StreakMath.currentStreak(entries: [], referenceDate: fixedDate(year: 2026, month: 7, day: 7), calendar: utcCalendar)
        XCTAssertEqual(streak, 0)
    }

    func testCurrentStreakCountsConsecutiveDays() {
        let day1 = fixedDate(year: 2026, month: 7, day: 5)
        let day2 = fixedDate(year: 2026, month: 7, day: 6)
        let day3 = fixedDate(year: 2026, month: 7, day: 7)
        let entries = [
            ColdEntry(date: day1, tookShower: true),
            ColdEntry(date: day2, tookShower: true),
            ColdEntry(date: day3, tookShower: true)
        ]
        let streak = StreakMath.currentStreak(entries: entries, referenceDate: day3, calendar: utcCalendar)
        XCTAssertEqual(streak, 3)
    }

    func testMissingDayBreaksStreak() {
        let day1 = fixedDate(year: 2026, month: 7, day: 5)
        // no entry for day 6
        let day3 = fixedDate(year: 2026, month: 7, day: 7)
        let entries = [
            ColdEntry(date: day1, tookShower: true),
            ColdEntry(date: day3, tookShower: true)
        ]
        let streak = StreakMath.currentStreak(entries: entries, referenceDate: day3, calendar: utcCalendar)
        XCTAssertEqual(streak, 1)
    }

    func testExplicitNoBreaksStreak() {
        let day1 = fixedDate(year: 2026, month: 7, day: 5)
        let day2 = fixedDate(year: 2026, month: 7, day: 6)
        let day3 = fixedDate(year: 2026, month: 7, day: 7)
        let entries = [
            ColdEntry(date: day1, tookShower: true),
            ColdEntry(date: day2, tookShower: false),
            ColdEntry(date: day3, tookShower: true)
        ]
        let streak = StreakMath.currentStreak(entries: entries, referenceDate: day3, calendar: utcCalendar)
        XCTAssertEqual(streak, 1)
    }

    // MARK: - Longest streak

    func testLongestStreakAcrossGaps() {
        // Two separate streaks: days 1-3 (3-long) and days 5-9 (5-long, the winner)
        let dates = [1, 2, 3, 5, 6, 7, 8, 9].map { fixedDate(year: 2026, month: 7, day: $0) }
        let entries = dates.map { ColdEntry(date: $0, tookShower: true) }
        let longest = StreakMath.longestStreak(entries: entries, calendar: utcCalendar)
        XCTAssertEqual(longest, 5)
    }

    func testLongestStreakIgnoresSkippedDays() {
        let entries = [
            ColdEntry(date: fixedDate(year: 2026, month: 7, day: 1), tookShower: true),
            ColdEntry(date: fixedDate(year: 2026, month: 7, day: 2), tookShower: false),
            ColdEntry(date: fixedDate(year: 2026, month: 7, day: 3), tookShower: true)
        ]
        let longest = StreakMath.longestStreak(entries: entries, calendar: utcCalendar)
        XCTAssertEqual(longest, 1)
    }

    // MARK: - Total cold showers

    func testTotalColdShowersCountsOnlyYes() {
        let entries = [
            ColdEntry(date: fixedDate(year: 2026, month: 7, day: 1), tookShower: true),
            ColdEntry(date: fixedDate(year: 2026, month: 7, day: 2), tookShower: false),
            ColdEntry(date: fixedDate(year: 2026, month: 7, day: 3), tookShower: true)
        ]
        XCTAssertEqual(StreakMath.totalColdShowers(entries: entries), 2)
    }

    // MARK: - Average duration

    func testAverageDurationOnlyCountsLoggedDurations() {
        let entries = [
            ColdEntry(date: fixedDate(year: 2026, month: 7, day: 1), tookShower: true, durationSeconds: 60),
            ColdEntry(date: fixedDate(year: 2026, month: 7, day: 2), tookShower: true, durationSeconds: 120),
            ColdEntry(date: fixedDate(year: 2026, month: 7, day: 3), tookShower: true, durationSeconds: nil)
        ]
        XCTAssertEqual(StreakMath.averageDurationSeconds(entries: entries), 90, accuracy: 0.001)
    }

    func testAverageDurationZeroWhenNoDurations() {
        let entries = [ColdEntry(date: fixedDate(year: 2026, month: 7, day: 1), tookShower: true)]
        XCTAssertEqual(StreakMath.averageDurationSeconds(entries: entries), 0, accuracy: 0.001)
    }

    // MARK: - Milestones

    func testHighestMilestoneForStreak() {
        XCTAssertNil(StreakMath.highestMilestone(for: 2))
        XCTAssertEqual(StreakMath.highestMilestone(for: 3), .three)
        XCTAssertEqual(StreakMath.highestMilestone(for: 10), .seven)
        XCTAssertEqual(StreakMath.highestMilestone(for: 100), .oneHundred)
        XCTAssertEqual(StreakMath.highestMilestone(for: 500), .oneHundred)
    }

    func testNewlyReachedMilestoneDetectsCrossing() {
        XCTAssertEqual(StreakMath.newlyReachedMilestone(oldStreak: 2, newStreak: 3), .three)
        XCTAssertNil(StreakMath.newlyReachedMilestone(oldStreak: 3, newStreak: 4))
        XCTAssertEqual(StreakMath.newlyReachedMilestone(oldStreak: 6, newStreak: 7), .seven)
    }

    // MARK: - Store behavior (marking today twice doesn't double count)

    func testLogTodayTwiceDoesNotDuplicateEntry() async {
        let store = await FrostlineStore()
        let today = Date()
        await MainActor.run {
            _ = store.logToday(tookShower: true, durationSeconds: 60, note: "first", referenceDate: today)
            _ = store.logToday(tookShower: true, durationSeconds: 90, note: "second", referenceDate: today)
        }
        let count = await MainActor.run { store.entries.filter { StreakMath.startOfDay($0.date) == StreakMath.startOfDay(today) }.count }
        XCTAssertEqual(count, 1)
        let entry = await MainActor.run { store.entry(on: today) }
        XCTAssertEqual(entry?.durationSeconds, 90)
        XCTAssertEqual(entry?.note, "second")
    }

    func testLogTodayYesExtendsStreak() async {
        let store = await FrostlineStore()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        await MainActor.run {
            _ = store.logToday(tookShower: true, durationSeconds: nil, note: "", referenceDate: yesterday)
            _ = store.logToday(tookShower: true, durationSeconds: nil, note: "", referenceDate: Date())
        }
        let streak = await MainActor.run { store.currentStreak() }
        XCTAssertEqual(streak, 2)
    }

    func testLogTodayNoBreaksStreak() async {
        let store = await FrostlineStore()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        await MainActor.run {
            _ = store.logToday(tookShower: true, durationSeconds: nil, note: "", referenceDate: yesterday)
            _ = store.logToday(tookShower: false, durationSeconds: nil, note: "", referenceDate: Date())
        }
        let streak = await MainActor.run { store.currentStreak() }
        XCTAssertEqual(streak, 0)
    }
}
