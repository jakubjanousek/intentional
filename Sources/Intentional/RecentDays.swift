import Foundation

struct DayStat: Equatable {
    let anchor: Date
    let focusSeconds: TimeInterval
    let intentionsDone: Int
}

enum RecentDays {
    static func summaries(
        from entries: [LogEntry],
        endingOn referenceDate: Date,
        days: Int,
        dailyResetHour: Int,
        calendar: Calendar = .current
    ) -> [DayStat] {
        guard days > 0 else { return [] }
        let todayAnchor = DailyAnchor.mostRecent(
            onOrBefore: referenceDate,
            hour: dailyResetHour,
            calendar: calendar
        )
        var anchors: [Date] = []
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: todayAnchor) else { continue }
            anchors.append(day)
        }
        anchors.reverse()

        var result: [DayStat] = []
        for (index, anchor) in anchors.enumerated() {
            let next: Date
            if index + 1 < anchors.count {
                next = anchors[index + 1]
            } else if let n = calendar.date(byAdding: .day, value: 1, to: anchor) {
                next = n
            } else {
                continue
            }
            let slice = entries.filter { $0.timestamp >= anchor && $0.timestamp < next }
            let summary = DailySummary.compute(from: slice, since: anchor)
            result.append(DayStat(
                anchor: anchor,
                focusSeconds: summary.focusSeconds,
                intentionsDone: summary.intentionsDone
            ))
        }
        return result
    }
}
