import Foundation
import Testing
@testable import Intentional

private func freshDefaults() -> UserDefaults {
    let suite = "intentional-test-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return defaults
}

@Test func defaultsMatchOnePagerNumbers() {
    let settings = Settings(defaults: freshDefaults())
    #expect(settings.pomodoroMinutes == 25)
    #expect(settings.debounceMinutes == 5)
    #expect(settings.dailyResetHour == 4)
}

@Test func valuesPersistAcrossInstances() {
    let defaults = freshDefaults()
    var settings = Settings(defaults: defaults)
    settings.pomodoroMinutes = 50
    settings.debounceMinutes = 10
    settings.dailyResetHour = 6

    let reloaded = Settings(defaults: defaults)
    #expect(reloaded.pomodoroMinutes == 50)
    #expect(reloaded.debounceMinutes == 10)
    #expect(reloaded.dailyResetHour == 6)
}

@Test func pomodoroMinutesClampsToValidRange() {
    var settings = Settings(defaults: freshDefaults())
    settings.pomodoroMinutes = 0
    #expect(settings.pomodoroMinutes == 5)
    settings.pomodoroMinutes = 200
    #expect(settings.pomodoroMinutes == 60)
}

@Test func debounceMinutesClampsToValidRange() {
    var settings = Settings(defaults: freshDefaults())
    settings.debounceMinutes = 0
    #expect(settings.debounceMinutes == 1)
    settings.debounceMinutes = 999
    #expect(settings.debounceMinutes == 30)
}

@Test func dailyResetHourClampsToValidRange() {
    var settings = Settings(defaults: freshDefaults())
    settings.dailyResetHour = -3
    #expect(settings.dailyResetHour == 0)
    settings.dailyResetHour = 25
    #expect(settings.dailyResetHour == 12)
}

@Test func launchAtLoginDefaultsToFalse() {
    let settings = Settings(defaults: freshDefaults())
    #expect(settings.launchAtLogin == false)
}

@Test func launchAtLoginPersists() {
    let defaults = freshDefaults()
    var settings = Settings(defaults: defaults)
    settings.launchAtLogin = true

    let reloaded = Settings(defaults: defaults)
    #expect(reloaded.launchAtLogin == true)
}

@Test func pomodoroDurationDerivesFromMinutes() {
    var settings = Settings(defaults: freshDefaults())
    settings.pomodoroMinutes = 30
    #expect(settings.pomodoroDuration == 30 * 60)
}
