import Foundation
import Testing
@testable import Intentional

private func date(_ iso: String) -> Date {
    let f = ISO8601DateFormatter()
    return f.date(from: iso)!
}

private let anchor = date("2026-05-24T04:00:00Z")

@Test func emptyLogYieldsNoIntentions() {
    let items = TodayLog.intentions(from: [], since: anchor)
    #expect(items.isEmpty)
}

@Test func ignoresEntriesBeforeAnchor() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-23T22:00:00Z"), type: .intention, intention: "yesterday"),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items.isEmpty)
}

@Test func intentionWithoutCheckInIsInProgress() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "write code"),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items.count == 1)
    #expect(items[0].intention == "write code")
    #expect(items[0].outcome == .inProgress)
}

@Test func pairsIntentionWithSubsequentCheckInDone() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "write code"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-24T09:25:30Z"), type: .checkInDone),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items.count == 1)
    #expect(items[0].outcome == .done)
}

@Test func pairsIntentionWithCheckInNotDone() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "drift"),
        LogEntry(timestamp: date("2026-05-24T09:25:30Z"), type: .checkInNotDone),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items[0].outcome == .notDone)
}

@Test func pairsIntentionWithCheckInSkipped() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "vanished"),
        LogEntry(timestamp: date("2026-05-24T09:25:30Z"), type: .checkInSkipped),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items[0].outcome == .skipped)
}

@Test func multipleIntentionsEachGetTheirNextCheckIn() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "first"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .checkInDone),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "second"),
        LogEntry(timestamp: date("2026-05-24T10:25:00Z"), type: .checkInNotDone),
        LogEntry(timestamp: date("2026-05-24T11:00:00Z"), type: .intention, intention: "third"),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items.count == 3)
    #expect(items[0].intention == "first")
    #expect(items[0].outcome == .done)
    #expect(items[1].intention == "second")
    #expect(items[1].outcome == .notDone)
    #expect(items[2].intention == "third")
    #expect(items[2].outcome == .inProgress)
}

@Test func ignoresCheckInsThatHaveNoPrecedingIntention() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .checkInDone),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "real one"),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items.count == 1)
    #expect(items[0].outcome == .inProgress)
}
