import Foundation
import Testing
@testable import Intentional

private func date(_ iso: String) -> Date {
    let f = ISO8601DateFormatter()
    return f.date(from: iso)!
}

private let anchor = date("2026-05-24T04:00:00Z")

@Test func summaryIgnoresEntriesBeforeAnchor() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-23T22:00:00Z"), type: .intention, intention: "yesterday"),
        LogEntry(timestamp: date("2026-05-24T03:00:00Z"), type: .checkInDone),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.intentionsSet == 0)
    #expect(summary.intentionsDone == 0)
}

@Test func summaryCountsByType() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "a"),
        LogEntry(timestamp: date("2026-05-24T09:30:00Z"), type: .checkInDone),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "b"),
        LogEntry(timestamp: date("2026-05-24T10:30:00Z"), type: .checkInNotDone),
        LogEntry(timestamp: date("2026-05-24T11:00:00Z"), type: .intention, intention: "c"),
        LogEntry(timestamp: date("2026-05-24T11:30:00Z"), type: .checkInSkipped),
        LogEntry(timestamp: date("2026-05-24T12:00:00Z"), type: .skipped),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.intentionsSet == 3)
    #expect(summary.intentionsDone == 1)
    #expect(summary.intentionsNotDone == 1)
    #expect(summary.intentionsSkipped == 1)
    #expect(summary.promptsSkipped == 1)
}

@Test func emptyDayHeadlineIsCalm() {
    let summary = DailySummary.compute(from: [], since: anchor)
    #expect(summary.headline == "Nothing logged today")
}

@Test func headlineWithOnlyIntentions() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "a"),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "b"),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.headline == "2 intentions today")
}

@Test func headlineWithIntentionsAndDone() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "a"),
        LogEntry(timestamp: date("2026-05-24T09:30:00Z"), type: .checkInDone),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "b"),
        LogEntry(timestamp: date("2026-05-24T10:30:00Z"), type: .checkInDone),
        LogEntry(timestamp: date("2026-05-24T11:00:00Z"), type: .intention, intention: "c"),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.headline == "3 intentions today · 2 done")
}

@Test func singleIntentionUsesSingular() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "only one"),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.headline == "1 intention today")
}

@Test func focusSecondsSumsCompletedPomodoros() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "a"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "b"),
        LogEntry(timestamp: date("2026-05-24T10:25:00Z"), type: .pomodoroCompleted),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.focusSeconds == 50 * 60)
}

@Test func focusSecondsIncludesEarlyEnded() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "a"),
        LogEntry(timestamp: date("2026-05-24T09:10:00Z"), type: .pomodoroEndedEarly),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.focusSeconds == 10 * 60)
}

@Test func focusSecondsSkipsInProgress() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "a"),
        // no terminal yet
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.focusSeconds == 0)
}

@Test func breakSecondsSumsCompleted() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .breakStarted),
        LogEntry(timestamp: date("2026-05-24T09:30:00Z"), type: .breakCompleted),
        LogEntry(timestamp: date("2026-05-24T10:25:00Z"), type: .breakStarted),
        LogEntry(timestamp: date("2026-05-24T10:27:00Z"), type: .breakEndedEarly),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.breakSeconds == 7 * 60)
}

@Test func breakSecondsSkipsInProgress() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .breakStarted),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.breakSeconds == 0)
}

@Test func focusAndBreakIgnoreEntriesBeforeAnchor() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-23T22:00:00Z"), type: .intention, intention: "yesterday"),
        LogEntry(timestamp: date("2026-05-23T22:25:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-23T22:25:00Z"), type: .breakStarted),
        LogEntry(timestamp: date("2026-05-23T22:30:00Z"), type: .breakCompleted),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.focusSeconds == 0)
    #expect(summary.breakSeconds == 0)
}
