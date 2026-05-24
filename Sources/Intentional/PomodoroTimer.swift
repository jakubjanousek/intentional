import Foundation

struct PomodoroTimer {
    enum State: Equatable {
        case idle
        case running(intention: String, startedAt: Date, duration: TimeInterval)
        case finished(intention: String, startedAt: Date, endedAt: Date, endedEarly: Bool)
        case resting(startedAt: Date, duration: TimeInterval)
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
    mutating func startRest(at startedAt: Date, duration: TimeInterval) -> Bool {
        guard duration > 0 else { return false }
        guard case let .finished(_, _, _, endedEarly) = state, endedEarly == false else {
            return false
        }
        state = .resting(startedAt: startedAt, duration: duration)
        return true
    }

    @discardableResult
    mutating func endRestEarly(at endedAt: Date) -> Bool {
        guard case .resting = state else { return false }
        _ = endedAt
        state = .idle
        return true
    }

    @discardableResult
    mutating func tick(at now: Date) -> Bool {
        switch state {
        case let .running(intention, startedAt, duration):
            guard now.timeIntervalSince(startedAt) >= duration else { return false }
            state = .finished(
                intention: intention,
                startedAt: startedAt,
                endedAt: startedAt.addingTimeInterval(duration),
                endedEarly: false
            )
            return true
        case let .resting(startedAt, duration):
            guard now.timeIntervalSince(startedAt) >= duration else { return false }
            state = .idle
            return true
        case .idle, .finished:
            return false
        }
    }

    func remaining(at now: Date) -> TimeInterval? {
        switch state {
        case let .running(_, startedAt, duration), let .resting(startedAt, duration):
            return max(0, duration - now.timeIntervalSince(startedAt))
        case .idle, .finished:
            return nil
        }
    }

    func elapsedFraction(at now: Date) -> Double? {
        switch state {
        case let .running(_, startedAt, duration), let .resting(startedAt, duration):
            let elapsed = now.timeIntervalSince(startedAt)
            return max(0, min(1, elapsed / duration))
        case .idle, .finished:
            return nil
        }
    }

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    var isResting: Bool {
        if case .resting = state { return true }
        return false
    }

    var currentIntention: String? {
        switch state {
        case .idle, .resting: return nil
        case .running(let intention, _, _): return intention
        case .finished(let intention, _, _, _): return intention
        }
    }
}
