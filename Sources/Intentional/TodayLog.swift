import Foundation

struct TodaysIntention: Equatable {
    enum Outcome: Equatable {
        case done
        case notDone
        case skipped
        case inProgress
    }

    let intention: String
    let startedAt: Date
    let outcome: Outcome
}

enum TodayLog {
    static func intentions(from entries: [LogEntry], since anchor: Date) -> [TodaysIntention] {
        let scoped = entries.filter { $0.timestamp >= anchor }
        var result: [TodaysIntention] = []
        for (index, entry) in scoped.enumerated() where entry.type == .intention {
            guard let text = entry.intention else { continue }
            let outcome = outcomeAfter(index: index, in: scoped)
            result.append(TodaysIntention(
                intention: text,
                startedAt: entry.timestamp,
                outcome: outcome
            ))
        }
        return result
    }

    private static func outcomeAfter(index: Int, in entries: [LogEntry]) -> TodaysIntention.Outcome {
        let tail = entries.suffix(from: index + 1)
        for entry in tail {
            if entry.type == .intention { return .inProgress }
            switch entry.type {
            case .checkInDone: return .done
            case .checkInNotDone: return .notDone
            case .checkInSkipped: return .skipped
            default: continue
            }
        }
        return .inProgress
    }
}
