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

@Test func intentionWithoutOutcomeIsInProgress() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "write code"),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items.count == 1)
    #expect(items[0].intention == "write code")
    #expect(items[0].outcome == .inProgress)
}

@Test func pairsIntentionWithSubsequentOutcomeDone() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "write code"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-24T09:25:30Z"), type: .outcomeDone),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items.count == 1)
    #expect(items[0].outcome == .done)
}

@Test func pairsIntentionWithOutcomeFailed() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "drift"),
        LogEntry(timestamp: date("2026-05-24T09:25:30Z"), type: .outcomeFailed),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items[0].outcome == .failed)
}

@Test func pairsIntentionWithOutcomeSkipped() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "vanished"),
        LogEntry(timestamp: date("2026-05-24T09:25:30Z"), type: .outcomeSkipped),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items[0].outcome == .skipped)
}

@Test func multipleIntentionsEachGetTheirNextOutcome() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "first"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .outcomeDone),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "second"),
        LogEntry(timestamp: date("2026-05-24T10:25:00Z"), type: .outcomeFailed),
        LogEntry(timestamp: date("2026-05-24T11:00:00Z"), type: .intention, intention: "third"),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items.count == 3)
    #expect(items[0].intention == "first")
    #expect(items[0].outcome == .done)
    #expect(items[1].intention == "second")
    #expect(items[1].outcome == .failed)
    #expect(items[2].intention == "third")
    #expect(items[2].outcome == .inProgress)
}

@Test func laterOutcomeOverridesEarlierOneForSameIntention() {
    // Pomodoro completes optimistically as done, user then marks it failed.
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "drifted"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-24T09:25:01Z"), type: .outcomeDone),
        LogEntry(timestamp: date("2026-05-24T09:26:00Z"), type: .outcomeFailed),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items.count == 1)
    #expect(items[0].outcome == .failed)
}

@Test func laterOutcomeFromAppendDoesNotLeakIntoNextIntention() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "first"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .outcomeDone),
        LogEntry(timestamp: date("2026-05-24T09:26:00Z"), type: .outcomeFailed),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "second"),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items[0].outcome == .failed)
    #expect(items[1].outcome == .inProgress)
}

@Test func deleteIntentionRemovesEntryAndItsOutcomes() {
    let start = date("2026-05-24T09:00:00Z")
    let entries: [LogEntry] = [
        LogEntry(timestamp: start, type: .intention, intention: "drop me"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-24T09:25:01Z"), type: .outcomeDone),
        LogEntry(timestamp: date("2026-05-24T09:26:00Z"), type: .outcomeFailed),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "keep"),
        LogEntry(timestamp: date("2026-05-24T10:25:00Z"), type: .outcomeDone),
    ]
    let result = TodayLog.deleteIntention(at: start, in: entries)
    let types = result.map { $0.type }
    #expect(!types.contains(.outcomeFailed))
    let remainingIntentions = result.filter { $0.type == .intention }
    #expect(remainingIntentions.count == 1)
    #expect(remainingIntentions[0].intention == "keep")
    // pomodoroCompleted (time tracking) is preserved
    #expect(types.contains(.pomodoroCompleted))
    // The next intention's outcome is still there
    #expect(result.last?.type == .outcomeDone)
}

@Test func deleteIntentionIsNoOpWhenTimestampDoesNotMatch() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "x"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .outcomeDone),
    ]
    let result = TodayLog.deleteIntention(at: date("2026-05-24T11:00:00Z"), in: entries)
    #expect(result.count == entries.count)
}

@Test func deleteIntentionLeavesTrailingPomodoroEventsAlone() {
    // Time-tracking events (pomodoroCompleted, breakStarted/Completed) survive
    // so focus and break stats stay accurate after a deletion.
    let start = date("2026-05-24T09:00:00Z")
    let entries: [LogEntry] = [
        LogEntry(timestamp: start, type: .intention, intention: "drop"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .breakStarted),
        LogEntry(timestamp: date("2026-05-24T09:25:01Z"), type: .outcomeDone),
        LogEntry(timestamp: date("2026-05-24T09:30:00Z"), type: .breakCompleted),
    ]
    let result = TodayLog.deleteIntention(at: start, in: entries)
    let types = result.map { $0.type }
    #expect(!types.contains(.intention))
    #expect(!types.contains(.outcomeDone))
    #expect(types.contains(.pomodoroCompleted))
    #expect(types.contains(.breakStarted))
    #expect(types.contains(.breakCompleted))
}

@Test func setOutcomeForOlderOngoingIntentionDoesNotLeakIntoLaterOne() {
    // The original bug: user marks an older still-ongoing intention as done,
    // but a newer intention has been logged since. Appending at end would
    // attribute the outcome to the newer intention; setOutcome must insert
    // between the target intention and the next one.
    let oldStart = date("2026-05-24T09:00:00Z")
    let entries: [LogEntry] = [
        LogEntry(timestamp: oldStart, type: .intention, intention: "old ongoing"),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "current"),
    ]
    let now = date("2026-05-24T10:30:00Z")
    let result = TodayLog.setOutcome(
        intentionAt: oldStart,
        to: .outcomeDone,
        timestamp: now,
        in: entries
    )
    let items = TodayLog.intentions(from: result, since: anchor)
    #expect(items.count == 2)
    #expect(items[0].intention == "old ongoing")
    #expect(items[0].outcome == .done)
    #expect(items[1].intention == "current")
    #expect(items[1].outcome == .inProgress)
}

@Test func setOutcomeReplacesPriorOutcomeForSameIntention() {
    let start = date("2026-05-24T09:00:00Z")
    let entries: [LogEntry] = [
        LogEntry(timestamp: start, type: .intention, intention: "x"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-24T09:25:01Z"), type: .outcomeDone),
    ]
    let result = TodayLog.setOutcome(
        intentionAt: start,
        to: .outcomeFailed,
        timestamp: date("2026-05-24T09:30:00Z"),
        in: entries
    )
    let outcomes = result.filter {
        $0.type == .outcomeDone || $0.type == .outcomeFailed || $0.type == .outcomeSkipped
    }
    #expect(outcomes.count == 1)
    #expect(outcomes[0].type == .outcomeFailed)
    // Time-tracking events survive.
    #expect(result.contains { $0.type == .pomodoroCompleted })
    let items = TodayLog.intentions(from: result, since: anchor)
    #expect(items[0].outcome == .failed)
}

@Test func setOutcomeIsNoOpWhenTimestampDoesNotMatch() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "x"),
    ]
    let result = TodayLog.setOutcome(
        intentionAt: date("2026-05-24T11:00:00Z"),
        to: .outcomeDone,
        timestamp: date("2026-05-24T11:30:00Z"),
        in: entries
    )
    #expect(result.count == entries.count)
    #expect(!result.contains { $0.type == .outcomeDone })
}

@Test func setOutcomeForLastIntentionInsertsAfterTrailingEvents() {
    let start = date("2026-05-24T09:00:00Z")
    let entries: [LogEntry] = [
        LogEntry(timestamp: start, type: .intention, intention: "x"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .pomodoroCompleted),
    ]
    let result = TodayLog.setOutcome(
        intentionAt: start,
        to: .outcomeDone,
        timestamp: date("2026-05-24T09:26:00Z"),
        in: entries
    )
    #expect(result.last?.type == .outcomeDone)
    let items = TodayLog.intentions(from: result, since: anchor)
    #expect(items[0].outcome == .done)
}

@Test func ignoresOutcomesThatHaveNoPrecedingIntention() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .outcomeDone),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "real one"),
    ]
    let items = TodayLog.intentions(from: entries, since: anchor)
    #expect(items.count == 1)
    #expect(items[0].outcome == .inProgress)
}
