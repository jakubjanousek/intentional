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
        LogEntry(timestamp: date("2026-05-24T03:00:00Z"), type: .outcomeDone),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.intentionsSet == 0)
    #expect(summary.intentionsDone == 0)
}

@Test func summaryCountsByType() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "a"),
        LogEntry(timestamp: date("2026-05-24T09:30:00Z"), type: .outcomeDone),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "b"),
        LogEntry(timestamp: date("2026-05-24T10:30:00Z"), type: .outcomeFailed),
        LogEntry(timestamp: date("2026-05-24T11:00:00Z"), type: .intention, intention: "c"),
        LogEntry(timestamp: date("2026-05-24T11:30:00Z"), type: .outcomeSkipped),
        LogEntry(timestamp: date("2026-05-24T12:00:00Z"), type: .skipped),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.intentionsSet == 3)
    #expect(summary.intentionsDone == 1)
    #expect(summary.intentionsFailed == 1)
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
        LogEntry(timestamp: date("2026-05-24T09:30:00Z"), type: .outcomeDone),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "b"),
        LogEntry(timestamp: date("2026-05-24T10:30:00Z"), type: .outcomeDone),
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

@Test func focusSecondsSuccessfulExcludesAbandoned() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "done"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .intention, intention: "abandoned"),
        LogEntry(timestamp: date("2026-05-24T10:05:00Z"), type: .pomodoroEndedEarly),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.focusSeconds == 30 * 60)
    #expect(summary.focusSecondsSuccessful == 25 * 60)
}

@Test func breakBetweenPomodorosCountsWhenIntentionFollowsQuickly() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .breakStarted),
        LogEntry(timestamp: date("2026-05-24T09:30:00Z"), type: .breakCompleted),
        LogEntry(timestamp: date("2026-05-24T09:31:00Z"), type: .intention, intention: "next"),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.breakSecondsBetweenPomodoros == 5 * 60)
}

@Test func breakBetweenPomodorosSkipsWhenUserAbandonedAfterBreak() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .breakStarted),
        LogEntry(timestamp: date("2026-05-24T09:30:00Z"), type: .breakCompleted),
        // user walked away; no intention follows
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.breakSecondsBetweenPomodoros == 0)
}

@Test func breakBetweenPomodorosSkipsWhenIntentionIsTooLate() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .breakStarted),
        LogEntry(timestamp: date("2026-05-24T09:30:00Z"), type: .breakCompleted),
        // intention is more than 10 minutes after break end
        LogEntry(timestamp: date("2026-05-24T09:45:00Z"), type: .intention, intention: "much later"),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.breakSecondsBetweenPomodoros == 0)
}

@Test func breakBetweenPomodorosCountsWhenEndedEarly() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .breakStarted),
        LogEntry(timestamp: date("2026-05-24T09:27:00Z"), type: .breakEndedEarly),
        LogEntry(timestamp: date("2026-05-24T09:27:30Z"), type: .intention, intention: "next"),
    ]
    let summary = DailySummary.compute(from: entries, since: anchor)
    #expect(summary.breakSecondsBetweenPomodoros == 2 * 60)
}

@Test func activeSecondsOffFocusSumsUnlockLockSpans() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T08:00:00Z"), type: .unlock),
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .lock),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .unlock),
        LogEntry(timestamp: date("2026-05-24T11:00:00Z"), type: .lock),
    ]
    let summary = DailySummary.compute(
        from: entries,
        since: anchor,
        until: date("2026-05-24T12:00:00Z")
    )
    // 2 hours of unlock-lock spans, no focus → 2h off-focus
    #expect(summary.activeSecondsOffFocus == 2 * 60 * 60)
}

@Test func activeSecondsOffFocusSubtractsFocus() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T08:00:00Z"), type: .unlock),
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .intention, intention: "x"),
        LogEntry(timestamp: date("2026-05-24T09:25:00Z"), type: .pomodoroCompleted),
        LogEntry(timestamp: date("2026-05-24T10:00:00Z"), type: .lock),
    ]
    let summary = DailySummary.compute(
        from: entries,
        since: anchor,
        until: date("2026-05-24T11:00:00Z")
    )
    // 2h active − 25m focus = 1h 35m off-focus
    let expected: TimeInterval = (2 * 60 * 60) - (25 * 60)
    #expect(summary.activeSecondsOffFocus == expected)
}

@Test func activeSecondsOffFocusIncludesOpenSessionUpToEndingAt() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T08:00:00Z"), type: .unlock),
    ]
    let summary = DailySummary.compute(
        from: entries,
        since: anchor,
        until: date("2026-05-24T09:00:00Z")
    )
    #expect(summary.activeSecondsOffFocus == 60 * 60)
}

@Test func activeSecondsOffFocusSubtractsBreakBetweenPomodoros() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T08:00:00Z"), type: .unlock),
        LogEntry(timestamp: date("2026-05-24T08:25:00Z"), type: .breakStarted),
        LogEntry(timestamp: date("2026-05-24T08:30:00Z"), type: .breakCompleted),
        LogEntry(timestamp: date("2026-05-24T08:31:00Z"), type: .intention, intention: "next"),
        LogEntry(timestamp: date("2026-05-24T08:56:00Z"), type: .pomodoroCompleted),
    ]
    let summary = DailySummary.compute(
        from: entries,
        since: anchor,
        until: date("2026-05-24T09:00:00Z")
    )
    // 1h active − 25m focus − 5m break = 30m off-focus
    let expected: TimeInterval = (60 * 60) - (25 * 60) - (5 * 60)
    #expect(summary.activeSecondsOffFocus == expected)
}

@Test func activeSecondsExcludesIdleGap() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T08:00:00Z"), type: .unlock),
        LogEntry(timestamp: date("2026-05-24T08:30:00Z"), type: .idleStarted),
        LogEntry(timestamp: date("2026-05-24T08:50:00Z"), type: .idleEnded),
        LogEntry(timestamp: date("2026-05-24T09:00:00Z"), type: .lock),
    ]
    let summary = DailySummary.compute(
        from: entries,
        since: anchor,
        until: date("2026-05-24T10:00:00Z")
    )
    // unlocked 60min, but 20min idle → 40min active
    #expect(summary.activeSecondsOffFocus == 40 * 60)
}

@Test func activeSecondsTreatsOpenIdleAsInactive() {
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T08:00:00Z"), type: .unlock),
        LogEntry(timestamp: date("2026-05-24T08:30:00Z"), type: .idleStarted),
        // no idleEnded — user still away
    ]
    let summary = DailySummary.compute(
        from: entries,
        since: anchor,
        until: date("2026-05-24T09:00:00Z")
    )
    // 30 minutes of active before going idle
    #expect(summary.activeSecondsOffFocus == 30 * 60)
}

@Test func activeSecondsSeedsEngagementFromPreAnchorUnlock() {
    // User unlocked the night before; daily anchor cuts mid-session.
    // The active stretch from anchor → first lock-after-anchor must still count.
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-23T20:00:00Z"), type: .unlock),
        LogEntry(timestamp: date("2026-05-24T05:00:00Z"), type: .lock),
    ]
    let summary = DailySummary.compute(
        from: entries,
        since: anchor,
        until: date("2026-05-24T06:00:00Z")
    )
    // anchor (04:00) → lock (05:00) = 60 min active, no focus → 60 min off-focus
    #expect(summary.activeSecondsOffFocus == 60 * 60)
}

@Test func activeSecondsIgnoresPreAnchorLockedState() {
    // If the user was locked when the anchor passed, don't seed engagement.
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-23T20:00:00Z"), type: .unlock),
        LogEntry(timestamp: date("2026-05-23T21:00:00Z"), type: .lock),
        LogEntry(timestamp: date("2026-05-24T07:00:00Z"), type: .unlock),
        LogEntry(timestamp: date("2026-05-24T08:00:00Z"), type: .lock),
    ]
    let summary = DailySummary.compute(
        from: entries,
        since: anchor,
        until: date("2026-05-24T09:00:00Z")
    )
    // Only the 07:00-08:00 span counts: 60 min off-focus.
    #expect(summary.activeSecondsOffFocus == 60 * 60)
}

@Test func activeSecondsSeedsEngagementWhenOnlyPostAnchorLockExists() {
    // No unlock after the anchor, just a lock — user must have been engaged at anchor.
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-23T22:00:00Z"), type: .unlock),
        LogEntry(timestamp: date("2026-05-24T05:30:00Z"), type: .lock),
    ]
    let summary = DailySummary.compute(
        from: entries,
        since: anchor,
        until: date("2026-05-24T06:00:00Z")
    )
    // anchor 04:00 → lock 05:30 = 90 min off-focus.
    #expect(summary.activeSecondsOffFocus == 90 * 60)
}

@Test func activeSecondsSortsOutOfOrderEntries() {
    // IdleMonitor stamps idleStarted at when input last occurred,
    // which can predate the append-position of the event.
    let entries: [LogEntry] = [
        LogEntry(timestamp: date("2026-05-24T08:00:00Z"), type: .unlock),
        LogEntry(timestamp: date("2026-05-24T08:35:00Z"), type: .idleEnded),
        LogEntry(timestamp: date("2026-05-24T08:30:00Z"), type: .idleStarted),
    ]
    let summary = DailySummary.compute(
        from: entries,
        since: anchor,
        until: date("2026-05-24T09:00:00Z")
    )
    // 30min active + 25min active = 55min
    #expect(summary.activeSecondsOffFocus == 55 * 60)
}
