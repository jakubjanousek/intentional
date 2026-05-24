import Foundation

struct Settings {
    static let pomodoroRange = 5...60
    static let debounceRange = 1...30
    static let dailyResetRange = 0...12
    static let breakRange = 1...30

    private enum Key {
        static let pomodoro = "pomodoroMinutes"
        static let debounce = "debounceMinutes"
        static let dailyReset = "dailyResetHour"
        static let launchAtLogin = "launchAtLogin"
        static let breakMinutes = "breakMinutes"
        static let breaksEnabled = "breaksEnabled"
    }

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var pomodoroMinutes: Int {
        get { read(Key.pomodoro, default: 25, in: Self.pomodoroRange) }
        set { defaults.set(Self.pomodoroRange.clamping(newValue), forKey: Key.pomodoro) }
    }

    var debounceMinutes: Int {
        get { read(Key.debounce, default: 5, in: Self.debounceRange) }
        set { defaults.set(Self.debounceRange.clamping(newValue), forKey: Key.debounce) }
    }

    var dailyResetHour: Int {
        get { read(Key.dailyReset, default: 4, in: Self.dailyResetRange) }
        set { defaults.set(Self.dailyResetRange.clamping(newValue), forKey: Key.dailyReset) }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Key.launchAtLogin) }
        set { defaults.set(newValue, forKey: Key.launchAtLogin) }
    }

    var breakMinutes: Int {
        get { read(Key.breakMinutes, default: 5, in: Self.breakRange) }
        set { defaults.set(Self.breakRange.clamping(newValue), forKey: Key.breakMinutes) }
    }

    var breaksEnabled: Bool {
        get {
            guard defaults.object(forKey: Key.breaksEnabled) != nil else { return true }
            return defaults.bool(forKey: Key.breaksEnabled)
        }
        set { defaults.set(newValue, forKey: Key.breaksEnabled) }
    }

    var pomodoroDuration: TimeInterval { TimeInterval(pomodoroMinutes * 60) }
    var debounceInterval: TimeInterval { TimeInterval(debounceMinutes * 60) }
    var breakDuration: TimeInterval { TimeInterval(breakMinutes * 60) }

    private func read(_ key: String, default fallback: Int, in range: ClosedRange<Int>) -> Int {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return range.clamping(defaults.integer(forKey: key))
    }
}

private extension ClosedRange where Bound == Int {
    func clamping(_ value: Int) -> Int { min(max(value, lowerBound), upperBound) }
}
