import Foundation

struct DailySummary {
    let intentionsSet: Int
    let intentionsDone: Int
    let intentionsNotDone: Int
    let intentionsSkipped: Int
    let promptsSkipped: Int
    let focusSeconds: TimeInterval
    let focusSecondsSuccessful: TimeInterval
    let breakSeconds: TimeInterval
    let breakSecondsBetweenPomodoros: TimeInterval
    let activeSecondsOffFocus: TimeInterval

    private static let breakReturnWindow: TimeInterval = 10 * 60

    static func compute(
        from entries: [LogEntry],
        since anchor: Date,
        until endingAt: Date = Date()
    ) -> DailySummary {
        let scoped = entries.filter { $0.timestamp >= anchor }
        let focus = pairedDuration(
            in: scoped,
            start: [.intention],
            end: [.pomodoroCompleted, .pomodoroEndedEarly]
        )
        let active = activeSeconds(in: scoped, until: endingAt)
        return DailySummary(
            intentionsSet: scoped.count { $0.type == .intention },
            intentionsDone: scoped.count { $0.type == .checkInDone },
            intentionsNotDone: scoped.count { $0.type == .checkInNotDone },
            intentionsSkipped: scoped.count { $0.type == .checkInSkipped },
            promptsSkipped: scoped.count { $0.type == .skipped },
            focusSeconds: focus,
            focusSecondsSuccessful: pairedDuration(
                in: scoped,
                start: [.intention],
                end: [.pomodoroCompleted]
            ),
            breakSeconds: pairedDuration(
                in: scoped,
                start: [.breakStarted],
                end: [.breakCompleted, .breakEndedEarly]
            ),
            breakSecondsBetweenPomodoros: breakBetweenPomodoros(in: scoped),
            activeSecondsOffFocus: max(0, active - focus)
        )
    }

    private static func pairedDuration(
        in entries: [LogEntry],
        start: Set<EventType>,
        end: Set<EventType>
    ) -> TimeInterval {
        var total: TimeInterval = 0
        for (index, entry) in entries.enumerated() where start.contains(entry.type) {
            let tail = entries.suffix(from: index + 1)
            for candidate in tail {
                if start.contains(candidate.type) { break }
                if end.contains(candidate.type) {
                    total += candidate.timestamp.timeIntervalSince(entry.timestamp)
                    break
                }
            }
        }
        return total
    }

    private static func breakBetweenPomodoros(in entries: [LogEntry]) -> TimeInterval {
        var total: TimeInterval = 0
        for (index, entry) in entries.enumerated() where entry.type == .breakStarted {
            let tail = entries.suffix(from: index + 1)
            var endedAt: Date?
            var endedEarly = false
            var qualifies = false
            for candidate in tail {
                if candidate.type == .breakStarted { break }
                if endedAt == nil {
                    switch candidate.type {
                    case .breakEndedEarly:
                        endedAt = candidate.timestamp
                        endedEarly = true
                    case .breakCompleted:
                        endedAt = candidate.timestamp
                    default:
                        continue
                    }
                    continue
                }
                if candidate.type == .intention, let endedAt {
                    let gap = candidate.timestamp.timeIntervalSince(endedAt)
                    if endedEarly || gap <= breakReturnWindow {
                        qualifies = true
                    }
                    break
                }
            }
            if endedEarly, !qualifies, endedAt != nil {
                qualifies = true
            }
            if qualifies, let endedAt {
                total += endedAt.timeIntervalSince(entry.timestamp)
            }
        }
        return total
    }

    private static func activeSeconds(in entries: [LogEntry], until endingAt: Date) -> TimeInterval {
        var total: TimeInterval = 0
        var sessionStart: Date?
        for entry in entries {
            switch entry.type {
            case .started, .unlock:
                if sessionStart == nil { sessionStart = entry.timestamp }
            case .lock:
                if let start = sessionStart, entry.timestamp > start {
                    total += entry.timestamp.timeIntervalSince(start)
                }
                sessionStart = nil
            default:
                continue
            }
        }
        if let start = sessionStart, endingAt > start {
            total += endingAt.timeIntervalSince(start)
        }
        return total
    }

    var headline: String {
        if intentionsSet == 0 { return "Nothing logged today" }
        let noun = intentionsSet == 1 ? "intention" : "intentions"
        if intentionsDone == 0 {
            return "\(intentionsSet) \(noun) today"
        }
        return "\(intentionsSet) \(noun) today · \(intentionsDone) done"
    }
}
