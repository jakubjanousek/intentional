import Foundation
import Testing
@testable import Intentional

private func date(_ iso: String) -> Date {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f.date(from: iso)!
}

private func fixedCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
}

@Test func firstUnlockEverPrompts() {
    let gate = UnlockGate(calendar: fixedCalendar())
    #expect(gate.shouldPrompt(unlockAt: date("2026-05-24T09:00:00Z")))
}

@Test func unlockAfterShortLockDoesNotPrompt() {
    var gate = UnlockGate(calendar: fixedCalendar())
    gate.recordPrompt(at: date("2026-05-24T08:55:00Z"))
    gate.recordLock(at: date("2026-05-24T08:58:00Z"))
    #expect(gate.shouldPrompt(unlockAt: date("2026-05-24T09:00:00Z")) == false)
}

@Test func unlockAfterLongLockPrompts() {
    var gate = UnlockGate(calendar: fixedCalendar())
    gate.recordPrompt(at: date("2026-05-24T08:00:00Z"))
    gate.recordLock(at: date("2026-05-24T08:30:00Z"))
    #expect(gate.shouldPrompt(unlockAt: date("2026-05-24T09:00:00Z")))
}

@Test func unlockAfterExactlyFiveMinuteLockPrompts() {
    var gate = UnlockGate(calendar: fixedCalendar())
    gate.recordPrompt(at: date("2026-05-24T08:00:00Z"))
    gate.recordLock(at: date("2026-05-24T08:55:00Z"))
    #expect(gate.shouldPrompt(unlockAt: date("2026-05-24T09:00:00Z")))
}

@Test func firstUnlockAfterDailyAnchorPromptsEvenWithShortLock() {
    var gate = UnlockGate(calendar: fixedCalendar())
    gate.recordPrompt(at: date("2026-05-23T22:00:00Z"))
    gate.recordLock(at: date("2026-05-24T08:58:00Z"))
    #expect(gate.shouldPrompt(unlockAt: date("2026-05-24T09:00:00Z")))
}

@Test func lastPromptBeforeFourAMTreatedAsPreviousDay() {
    var gate = UnlockGate(calendar: fixedCalendar())
    gate.recordPrompt(at: date("2026-05-24T03:30:00Z"))
    gate.recordLock(at: date("2026-05-24T08:58:00Z"))
    #expect(gate.shouldPrompt(unlockAt: date("2026-05-24T09:00:00Z")))
}

@Test func lastPromptAfterFourAMSuppressesShortLockUnlock() {
    var gate = UnlockGate(calendar: fixedCalendar())
    gate.recordPrompt(at: date("2026-05-24T08:00:00Z"))
    gate.recordLock(at: date("2026-05-24T08:58:00Z"))
    #expect(gate.shouldPrompt(unlockAt: date("2026-05-24T09:00:00Z")) == false)
}

@Test func recordPromptSuppressesImmediateRePrompt() {
    var gate = UnlockGate(calendar: fixedCalendar())
    gate.recordPrompt(at: date("2026-05-24T09:00:00Z"))
    #expect(gate.shouldPrompt(unlockAt: date("2026-05-24T09:00:30Z")) == false)
}

@Test func noLockEverButLastPromptYesterdayPrompts() {
    var gate = UnlockGate(calendar: fixedCalendar())
    gate.recordPrompt(at: date("2026-05-23T15:00:00Z"))
    #expect(gate.shouldPrompt(unlockAt: date("2026-05-24T09:00:00Z")))
}
