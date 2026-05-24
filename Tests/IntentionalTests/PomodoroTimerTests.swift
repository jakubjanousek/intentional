import Foundation
import Testing
@testable import Intentional

private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
private let twentyFive: TimeInterval = 25 * 60

@Test func newTimerIsIdle() {
    let timer = PomodoroTimer()
    #expect(timer.state == .idle)
    #expect(timer.remaining(at: t0) == nil)
    #expect(timer.elapsedFraction(at: t0) == nil)
    #expect(timer.currentIntention == nil)
}

@Test func startTransitionsToRunning() {
    var timer = PomodoroTimer()
    let ok = timer.start(intention: "write tests", at: t0, duration: twentyFive)
    #expect(ok)
    #expect(timer.currentIntention == "write tests")
    #expect(timer.remaining(at: t0) == twentyFive)
    #expect(timer.elapsedFraction(at: t0) == 0)
}

@Test func remainingAndFractionAtMidpoint() {
    var timer = PomodoroTimer()
    timer.start(intention: "x", at: t0, duration: twentyFive)
    let midpoint = t0.addingTimeInterval(twentyFive / 2)
    #expect(timer.remaining(at: midpoint) == twentyFive / 2)
    #expect(timer.elapsedFraction(at: midpoint) == 0.5)
}

@Test func remainingClampsToZeroPastDuration() {
    var timer = PomodoroTimer()
    timer.start(intention: "x", at: t0, duration: twentyFive)
    let past = t0.addingTimeInterval(twentyFive + 30)
    #expect(timer.remaining(at: past) == 0)
    #expect(timer.elapsedFraction(at: past) == 1)
}

@Test func tickReturnsTrueOnceWhenDurationElapses() {
    var timer = PomodoroTimer()
    timer.start(intention: "x", at: t0, duration: twentyFive)
    #expect(timer.tick(at: t0.addingTimeInterval(60)) == false)
    #expect(timer.tick(at: t0.addingTimeInterval(twentyFive)) == true)
    #expect(timer.tick(at: t0.addingTimeInterval(twentyFive + 1)) == false)
}

@Test func tickOnIdleIsNoop() {
    var timer = PomodoroTimer()
    #expect(timer.tick(at: t0) == false)
    #expect(timer.state == .idle)
}

@Test func finishedStateRetainsIntention() {
    var timer = PomodoroTimer()
    timer.start(intention: "ship pomodoro", at: t0, duration: twentyFive)
    _ = timer.tick(at: t0.addingTimeInterval(twentyFive))
    #expect(timer.currentIntention == "ship pomodoro")
    if case let .finished(_, _, _, endedEarly) = timer.state {
        #expect(endedEarly == false)
    } else {
        Issue.record("expected finished state")
    }
}

@Test func endEarlyMarksEndedEarly() {
    var timer = PomodoroTimer()
    timer.start(intention: "x", at: t0, duration: twentyFive)
    let ok = timer.endEarly(at: t0.addingTimeInterval(60))
    #expect(ok)
    if case let .finished(_, _, _, endedEarly) = timer.state {
        #expect(endedEarly == true)
    } else {
        Issue.record("expected finished state")
    }
}

@Test func endEarlyOnIdleReturnsFalse() {
    var timer = PomodoroTimer()
    #expect(timer.endEarly(at: t0) == false)
}

@Test func startRejectsNonPositiveDuration() {
    var timer = PomodoroTimer()
    #expect(timer.start(intention: "x", at: t0, duration: 0) == false)
    #expect(timer.start(intention: "x", at: t0, duration: -5) == false)
    #expect(timer.state == .idle)
}

@Test func startReplacesPreviousRun() {
    var timer = PomodoroTimer()
    timer.start(intention: "first", at: t0, duration: twentyFive)
    let later = t0.addingTimeInterval(60)
    timer.start(intention: "second", at: later, duration: twentyFive)
    #expect(timer.currentIntention == "second")
    #expect(timer.remaining(at: later) == twentyFive)
}
