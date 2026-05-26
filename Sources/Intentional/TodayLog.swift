import Foundation

struct TodaysIntention: Equatable {
    enum Outcome: Equatable {
        case done
        case failed
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

    static func setOutcome(
        intentionAt startedAt: Date,
        to type: EventType,
        timestamp: Date,
        in entries: [LogEntry]
    ) -> [LogEntry] {
        guard let index = entries.firstIndex(where: {
            $0.type == .intention && $0.timestamp == startedAt
        }) else {
            return entries
        }
        let outcomeTypes: Set<EventType> = [.outcomeDone, .outcomeFailed, .outcomeSkipped]
        var result = entries
        var i = index + 1
        var insertAt = index + 1
        while i < result.count {
            if result[i].type == .intention { break }
            if outcomeTypes.contains(result[i].type) {
                result.remove(at: i)
                continue
            }
            i += 1
            insertAt = i
        }
        result.insert(LogEntry(timestamp: timestamp, type: type), at: insertAt)
        return result
    }

    static func deleteIntention(at startedAt: Date, in entries: [LogEntry]) -> [LogEntry] {
        guard let index = entries.firstIndex(where: {
            $0.type == .intention && $0.timestamp == startedAt
        }) else {
            return entries
        }
        let outcomeTypes: Set<EventType> = [.outcomeDone, .outcomeFailed, .outcomeSkipped]
        var indexesToRemove = [index]
        var i = index + 1
        while i < entries.count {
            if entries[i].type == .intention { break }
            if outcomeTypes.contains(entries[i].type) {
                indexesToRemove.append(i)
            }
            i += 1
        }
        var result = entries
        for offset in indexesToRemove.reversed() {
            result.remove(at: offset)
        }
        return result
    }

    private static func outcomeAfter(index: Int, in entries: [LogEntry]) -> TodaysIntention.Outcome {
        var current: TodaysIntention.Outcome = .inProgress
        let tail = entries.suffix(from: index + 1)
        for entry in tail {
            if entry.type == .intention { break }
            switch entry.type {
            case .outcomeDone: current = .done
            case .outcomeFailed: current = .failed
            case .outcomeSkipped: current = .skipped
            default: continue
            }
        }
        return current
    }
}
