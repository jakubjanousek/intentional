import Foundation

struct DailySummary {
    let intentionsSet: Int
    let intentionsDone: Int
    let intentionsNotDone: Int
    let intentionsSkipped: Int
    let promptsSkipped: Int
    let focusSeconds: TimeInterval
    let breakSeconds: TimeInterval

    static func compute(from entries: [LogEntry], since anchor: Date) -> DailySummary {
        let scoped = entries.filter { $0.timestamp >= anchor }
        return DailySummary(
            intentionsSet: scoped.count { $0.type == .intention },
            intentionsDone: scoped.count { $0.type == .checkInDone },
            intentionsNotDone: scoped.count { $0.type == .checkInNotDone },
            intentionsSkipped: scoped.count { $0.type == .checkInSkipped },
            promptsSkipped: scoped.count { $0.type == .skipped },
            focusSeconds: pairedDuration(
                in: scoped,
                start: [.intention],
                end: [.pomodoroCompleted, .pomodoroEndedEarly]
            ),
            breakSeconds: pairedDuration(
                in: scoped,
                start: [.breakStarted],
                end: [.breakCompleted, .breakEndedEarly]
            )
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

    var headline: String {
        if intentionsSet == 0 { return "Nothing logged today" }
        let noun = intentionsSet == 1 ? "intention" : "intentions"
        if intentionsDone == 0 {
            return "\(intentionsSet) \(noun) today"
        }
        return "\(intentionsSet) \(noun) today · \(intentionsDone) done"
    }
}
