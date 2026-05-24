import Foundation

struct DailySummary {
    let intentionsSet: Int
    let intentionsDone: Int
    let intentionsNotDone: Int
    let intentionsSkipped: Int
    let promptsSkipped: Int

    static func compute(from entries: [LogEntry], since anchor: Date) -> DailySummary {
        let scoped = entries.filter { $0.timestamp >= anchor }
        return DailySummary(
            intentionsSet: scoped.count { $0.type == .intention },
            intentionsDone: scoped.count { $0.type == .checkInDone },
            intentionsNotDone: scoped.count { $0.type == .checkInNotDone },
            intentionsSkipped: scoped.count { $0.type == .checkInSkipped },
            promptsSkipped: scoped.count { $0.type == .skipped }
        )
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

private extension Array {
    func count(where predicate: (Element) -> Bool) -> Int {
        reduce(0) { predicate($1) ? $0 + 1 : $0 }
    }
}
