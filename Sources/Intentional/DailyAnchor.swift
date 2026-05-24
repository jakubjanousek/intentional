import Foundation

enum DailyAnchor {
    static func mostRecent(
        onOrBefore date: Date,
        hour: Int,
        calendar: Calendar = .current
    ) -> Date {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        var anchorComponents = components
        anchorComponents.hour = hour
        anchorComponents.minute = 0
        anchorComponents.second = 0
        let anchorToday = calendar.date(from: anchorComponents)!
        if anchorToday <= date {
            return anchorToday
        }
        return calendar.date(byAdding: .day, value: -1, to: anchorToday)!
    }
}
