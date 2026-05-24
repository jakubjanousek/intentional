import Foundation

struct UnlockGate {
    var minLockDuration: TimeInterval = 5 * 60
    var dailyResetHour: Int = 4
    var calendar: Calendar

    private var lastLockAt: Date?
    private var lastPromptAt: Date?

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    mutating func recordLock(at date: Date) {
        lastLockAt = date
    }

    mutating func recordPrompt(at date: Date) {
        lastPromptAt = date
    }

    func shouldPrompt(unlockAt: Date) -> Bool {
        if isFirstUnlockAfterDailyAnchor(at: unlockAt) {
            return true
        }
        if let lockedAt = lastLockAt, unlockAt.timeIntervalSince(lockedAt) >= minLockDuration {
            return true
        }
        return false
    }

    private func isFirstUnlockAfterDailyAnchor(at unlockAt: Date) -> Bool {
        guard let lastPromptAt else { return true }
        let anchor = dailyAnchor(onOrBefore: unlockAt)
        return lastPromptAt < anchor
    }

    private func dailyAnchor(onOrBefore date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        var anchorComponents = components
        anchorComponents.hour = dailyResetHour
        anchorComponents.minute = 0
        anchorComponents.second = 0
        let anchorToday = calendar.date(from: anchorComponents)!
        if anchorToday <= date {
            return anchorToday
        }
        return calendar.date(byAdding: .day, value: -1, to: anchorToday)!
    }
}
