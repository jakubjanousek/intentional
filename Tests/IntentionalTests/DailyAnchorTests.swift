import Foundation
import Testing
@testable import Intentional

private func date(_ iso: String) -> Date {
    let f = ISO8601DateFormatter()
    return f.date(from: iso)!
}

private func utcCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
}

@Test func anchorIsTodayAtHourWhenPastIt() {
    let result = DailyAnchor.mostRecent(
        onOrBefore: date("2026-05-24T09:30:00Z"),
        hour: 4,
        calendar: utcCalendar()
    )
    #expect(result == date("2026-05-24T04:00:00Z"))
}

@Test func anchorIsYesterdayWhenBeforeHourToday() {
    let result = DailyAnchor.mostRecent(
        onOrBefore: date("2026-05-24T03:00:00Z"),
        hour: 4,
        calendar: utcCalendar()
    )
    #expect(result == date("2026-05-23T04:00:00Z"))
}

@Test func anchorAtExactHourIsToday() {
    let result = DailyAnchor.mostRecent(
        onOrBefore: date("2026-05-24T04:00:00Z"),
        hour: 4,
        calendar: utcCalendar()
    )
    #expect(result == date("2026-05-24T04:00:00Z"))
}

@Test func anchorRespectsHourZero() {
    let result = DailyAnchor.mostRecent(
        onOrBefore: date("2026-05-24T12:00:00Z"),
        hour: 0,
        calendar: utcCalendar()
    )
    #expect(result == date("2026-05-24T00:00:00Z"))
}
