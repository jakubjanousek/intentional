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

@Test func breakMinutesDefaultsToFive() {
    let settings = Settings(defaults: freshDefaults())
    #expect(settings.breakMinutes == 5)
}

@Test func breakMinutesClampsToValidRange() {
    var settings = Settings(defaults: freshDefaults())
    settings.breakMinutes = 0
    #expect(settings.breakMinutes == 1)
    settings.breakMinutes = 999
    #expect(settings.breakMinutes == 30)
}

@Test func breakMinutesPersists() {
    let defaults = freshDefaults()
    var settings = Settings(defaults: defaults)
    settings.breakMinutes = 12
    let reloaded = Settings(defaults: defaults)
    #expect(reloaded.breakMinutes == 12)
}

@Test func breakDurationDerivesFromMinutes() {
    var settings = Settings(defaults: freshDefaults())
    settings.breakMinutes = 7
    #expect(settings.breakDuration == 7 * 60)
}

@Test func breaksEnabledDefaultsToTrue() {
    let settings = Settings(defaults: freshDefaults())
    #expect(settings.breaksEnabled == true)
}

@Test func breaksEnabledPersists() {
    let defaults = freshDefaults()
    var settings = Settings(defaults: defaults)
    settings.breaksEnabled = false
    let reloaded = Settings(defaults: defaults)
    #expect(reloaded.breaksEnabled == false)
}

@Test func breakEndSoundDefaultsToTrue() {
    let settings = Settings(defaults: freshDefaults())
    #expect(settings.breakEndSoundEnabled == true)
}

@Test func breakEndSoundPersists() {
    let defaults = freshDefaults()
    var settings = Settings(defaults: defaults)
    settings.breakEndSoundEnabled = false
    let reloaded = Settings(defaults: defaults)
    #expect(reloaded.breakEndSoundEnabled == false)
}

@Test func showIntentionInMenuBarDefaultsToTrue() {
    let settings = Settings(defaults: freshDefaults())
    #expect(settings.showIntentionInMenuBar == true)
}

@Test func showIntentionInMenuBarPersists() {
    let defaults = freshDefaults()
    var settings = Settings(defaults: defaults)
    settings.showIntentionInMenuBar = false
    let reloaded = Settings(defaults: defaults)
    #expect(reloaded.showIntentionInMenuBar == false)
}

@Test func pomodoroEndSoundDefaultsToTrue() {
    let settings = Settings(defaults: freshDefaults())
    #expect(settings.pomodoroEndSoundEnabled == true)
}

@Test func pomodoroEndSoundPersists() {
    let defaults = freshDefaults()
    var settings = Settings(defaults: defaults)
    settings.pomodoroEndSoundEnabled = false
    let reloaded = Settings(defaults: defaults)
    #expect(reloaded.pomodoroEndSoundEnabled == false)
}

@Test func skipReminderMinutesDefaultsToFifteen() {
    let settings = Settings(defaults: freshDefaults())
    #expect(settings.skipReminderMinutes == 15)
}

@Test func skipReminderMinutesClampsToValidRange() {
    var settings = Settings(defaults: freshDefaults())
    settings.skipReminderMinutes = 0
    #expect(settings.skipReminderMinutes == 1)
    settings.skipReminderMinutes = 999
    #expect(settings.skipReminderMinutes == 60)
}

@Test func skipReminderMinutesPersists() {
    let defaults = freshDefaults()
    var settings = Settings(defaults: defaults)
    settings.skipReminderMinutes = 20
    let reloaded = Settings(defaults: defaults)
    #expect(reloaded.skipReminderMinutes == 20)
}

@Test func skipReminderDurationDerivesFromMinutes() {
    var settings = Settings(defaults: freshDefaults())
    settings.skipReminderMinutes = 10
    #expect(settings.skipReminderDuration == 10 * 60)
}
