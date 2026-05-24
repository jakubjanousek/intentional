import Foundation

struct PomodoroTimer {
    enum State: Equatable {
        case idle
        case running(intention: String, startedAt: Date, duration: TimeInterval)
        case finished(intention: String, startedAt: Date, endedAt: Date, endedEarly: Bool)
    }

    private(set) var state: State = .idle

    @discardableResult
    mutating func start(intention: String, at startedAt: Date, duration: TimeInterval) -> Bool {
        guard duration > 0 else { return false }
        state = .running(intention: intention, startedAt: startedAt, duration: duration)
        return true
    }

    @discardableResult
    mutating func endEarly(at endedAt: Date) -> Bool {
        guard case let .running(intention, startedAt, _) = state else { return false }
        state = .finished(
            intention: intention,
            startedAt: startedAt,
            endedAt: endedAt,
            endedEarly: true
        )
        return true
    }

    @discardableResult
    mutating func tick(at now: Date) -> Bool {
        guard case let .running(intention, startedAt, duration) = state else { return false }
        guard now.timeIntervalSince(startedAt) >= duration else { return false }
        state = .finished(
            intention: intention,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(duration),
            endedEarly: false
        )
        return true
    }

    func remaining(at now: Date) -> TimeInterval? {
        guard case let .running(_, startedAt, duration) = state else { return nil }
        return max(0, duration - now.timeIntervalSince(startedAt))
    }

    func elapsedFraction(at now: Date) -> Double? {
        guard case let .running(_, startedAt, duration) = state else { return nil }
        let elapsed = now.timeIntervalSince(startedAt)
        return max(0, min(1, elapsed / duration))
    }

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    var currentIntention: String? {
        switch state {
        case .idle: return nil
        case .running(let intention, _, _): return intention
        case .finished(let intention, _, _, _): return intention
        }
    }
}
