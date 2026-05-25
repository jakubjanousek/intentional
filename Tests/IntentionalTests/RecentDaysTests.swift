import Foundation
import Testing
@testable import Intentional

private func date(_ iso: String) -> Date {
    let f = ISO8601DateFormatter()
    return f.date(from: iso)!
}

private func fixedCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
}

@Test func recentDaysReturnsRequestedCountInChronologicalOrder() {
    let result = RecentDays.summaries(
        from: [],
        endingOn: date("2026-05-25T15:00:00Z"),
        days: 7,
        dailyResetHour: 4,
        calendar: fixedCalendar()
    )
    #expect(result.count == 7)
    for i in 1..<result.count {
        #expect(result[i - 1].anchor < result[i].anchor)
    }
}

@Test func recentDaysLastAnchorIsTodaysAnchor() {
    let result = RecentDays.summaries(
        from: [],
        endingOn: date("2026-05-25T15:00:00Z"),
        days: 7,
        dailyResetHour: 4,
        calendar: fixedCalendar()
    )
    #expect(result.last?.anchor == date("2026-05-25T04:00:00Z"))
}

@Test func recentDaysEmptyEntriesGivesZeros() {
    let result = RecentDays.summaries(
        from: [],
        endingOn: date("2026-05-25T15:00:00Z"),
        days: 7,
        dailyResetHour: 4,
        calendar: fixedCalendar()
    )
    for stat in result {
        #expect(stat.focusSeconds == 0)
        #expect(stat.intentionsDone == 0)
    }
}

@Test func recentDaysAttributesFocusAndDoneToCorrectDay() throws {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-23T10:00:00Z"), type: .intention, intention: "x"),
        LogEntry(timestamp: date("2026-05-23T10:25:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-23T11:00:00Z"), type: .checkInDone),
        LogEntry(timestamp: date("2026-05-25T09:00:00Z"), type: .intention, intention: "y"),
        LogEntry(timestamp: date("2026-05-25T09:30:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-25T09:31:00Z"), type: .checkInDone),
    ]
    let result = RecentDays.summaries(
        from: entries,
        endingOn: date("2026-05-25T15:00:00Z"),
        days: 7,
        dailyResetHour: 4,
        calendar: fixedCalendar()
    )
    let today = try #require(result.last)
    #expect(today.focusSeconds == 30 * 60)
    #expect(today.intentionsDone == 1)
    let twoAgo = result[result.count - 3]
    #expect(twoAgo.focusSeconds == 25 * 60)
    #expect(twoAgo.intentionsDone == 1)
    let yesterday = result[result.count - 2]
    #expect(yesterday.focusSeconds == 0)
    #expect(yesterday.intentionsDone == 0)
}

@Test func recentDaysIgnoresEntriesBeyondWindow() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-15T10:00:00Z"), type: .intention, intention: "old"),
        LogEntry(timestamp: date("2026-05-15T10:25:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-15T10:26:00Z"), type: .checkInDone),
    ]
    let result = RecentDays.summaries(
        from: entries,
        endingOn: date("2026-05-25T15:00:00Z"),
        days: 7,
        dailyResetHour: 4,
        calendar: fixedCalendar()
    )
    let totalFocus = result.reduce(0) { $0 + $1.focusSeconds }
    let totalDone = result.reduce(0) { $0 + $1.intentionsDone }
    #expect(totalFocus == 0)
    #expect(totalDone == 0)
}

@Test func recentDaysRespectsDailyResetHour() {
    let entries: [LogEntry] = [
        // 02:00 UTC on day N+1 is *before* the 4am anchor, so it belongs to day N
        LogEntry(timestamp: date("2026-05-24T02:00:00Z"), type: .intention, intention: "late"),
        LogEntry(timestamp: date("2026-05-24T02:25:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-24T02:26:00Z"), type: .checkInDone),
    ]
    let result = RecentDays.summaries(
        from: entries,
        endingOn: date("2026-05-25T15:00:00Z"),
        days: 7,
        dailyResetHour: 4,
        calendar: fixedCalendar()
    )
    // Today is the 25th (4am anchor). 24th 02:00 falls before the 24th's 4am
    // anchor, so it belongs to the 23rd's day (index = last - 2).
    let twoAgo = result[result.count - 3]
    #expect(twoAgo.focusSeconds == 25 * 60)
    #expect(twoAgo.intentionsDone == 1)
}
