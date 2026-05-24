import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let log = EventLog(fileURL: EventLog.defaultLocation())
    private var settings = Settings()

    private var statusItem: NSStatusItem!
    private var unlockMonitor: UnlockMonitor!
    private var promptPanel: IntentionPromptPanel!
    private var checkInPanel: CheckInPanel!
    private var settingsWindow: SettingsWindow!
    private var todayWindow: TodayWindow!
    private var gate = UnlockGate()
    private var pomodoro = PomodoroTimer()
    private var tickTimer: Timer?

    private var intentionItem: NSMenuItem!
    private var remainingItem: NSMenuItem!
    private var endEarlyItem: NSMenuItem!
    private var promptNowItem: NSMenuItem!
    private var runningSeparator: NSMenuItem!
    private var summaryItem: NSMenuItem!
    private var summarySeparator: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = MenuBarRingIcon.idle
            button.toolTip = "Intentional"
        }

        let menu = buildMenu()
        menu.delegate = self
        statusItem.menu = menu

        promptPanel = IntentionPromptPanel()
        checkInPanel = CheckInPanel()
        settingsWindow = SettingsWindow()
        settingsWindow.onChange = { [weak self] in self?.settingsDidChange() }
        todayWindow = TodayWindow(log: log, settingsProvider: { [weak self] in
            self?.settings ?? Settings()
        })

        applySettings()

        unlockMonitor = UnlockMonitor()
        unlockMonitor.onUnlock = { [weak self] date in self?.handleUnlock(at: date) }
        unlockMonitor.onLock = { [weak self] date in self?.handleLock(at: date) }
        unlockMonitor.start()

        write(LogEntry(timestamp: Date(), type: .started))
        refreshMenuVisibility()
    }

    private func applySettings() {
        gate.minLockDuration = settings.debounceInterval
        gate.dailyResetHour = settings.dailyResetHour
        syncLaunchAtLogin()
    }

    private func syncLaunchAtLogin() {
        guard LaunchAtLogin.isAvailable else { return }
        do {
            try LaunchAtLogin.setEnabled(settings.launchAtLogin)
        } catch {
            NSLog("Intentional: launch-at-login sync failed: \(error)")
            settings.launchAtLogin = false
        }
    }

    func settingsDidChange() {
        settings = Settings()
        applySettings()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        intentionItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        intentionItem.isEnabled = false
        menu.addItem(intentionItem)

        remainingItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        remainingItem.isEnabled = false
        menu.addItem(remainingItem)

        endEarlyItem = NSMenuItem(
            title: "End Early",
            action: #selector(endEarly),
            keyEquivalent: "e"
        )
        endEarlyItem.target = self
        menu.addItem(endEarlyItem)

        runningSeparator = NSMenuItem.separator()
        menu.addItem(runningSeparator)

        summaryItem = NSMenuItem(title: "Nothing logged today", action: nil, keyEquivalent: "")
        summaryItem.isEnabled = false
        menu.addItem(summaryItem)

        let todayItem = NSMenuItem(
            title: "Today’s Intentions…",
            action: #selector(openToday),
            keyEquivalent: "t"
        )
        todayItem.target = self
        menu.addItem(todayItem)

        summarySeparator = NSMenuItem.separator()
        menu.addItem(summarySeparator)

        promptNowItem = NSMenuItem(
            title: "Prompt Now",
            action: #selector(promptNow),
            keyEquivalent: "p"
        )
        promptNowItem.target = self
        menu.addItem(promptNowItem)

        let revealItem = NSMenuItem(
            title: "Reveal Log in Finder",
            action: #selector(revealLog),
            keyEquivalent: "l"
        )
        revealItem.target = self
        menu.addItem(revealItem)

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit Intentional",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        return menu
    }

    // MARK: - Unlock flow

    private func handleUnlock(at date: Date) {
        write(LogEntry(timestamp: date, type: .unlock))
        guard gate.shouldPrompt(unlockAt: date) else { return }
        showPrompt(at: date)
    }

    private func handleLock(at date: Date) {
        write(LogEntry(timestamp: date, type: .lock))
        gate.recordLock(at: date)
    }

    @objc private func promptNow() {
        showPrompt(at: Date())
    }

    private func showPrompt(at date: Date) {
        write(LogEntry(timestamp: date, type: .prompted))
        gate.recordPrompt(at: date)
        let prefill = (try? log.lastIntention()) ?? nil
        promptPanel.present(
            prefill: prefill,
            onStart: { [weak self] intention in self?.startPomodoro(with: intention) },
            onSkip: { [weak self] in
                self?.write(LogEntry(timestamp: Date(), type: .skipped))
            }
        )
    }

    // MARK: - Pomodoro lifecycle

    private func startPomodoro(with intention: String) {
        let now = Date()

        if pomodoro.isRunning {
            write(LogEntry(timestamp: now, type: .pomodoroEndedEarly))
        }

        write(LogEntry(timestamp: now, type: .intention, intention: intention))
        pomodoro.start(intention: intention, at: now, duration: settings.pomodoroDuration)
        refreshMenuVisibility()
        refreshLiveLabels(now: now)
        startTickLoop()
    }

    private func startTickLoop() {
        tickTimer?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
    }

    private func stopTickLoop() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func tick() {
        let now = Date()
        if pomodoro.tick(at: now) {
            pomodoroDidComplete(at: now)
            return
        }
        refreshLiveLabels(now: now)
    }

    @objc private func endEarly() {
        let now = Date()
        guard pomodoro.endEarly(at: now) else { return }
        write(LogEntry(timestamp: now, type: .pomodoroEndedEarly))
        finishPomodoro(intention: pomodoro.currentIntention)
    }

    private func pomodoroDidComplete(at date: Date) {
        write(LogEntry(timestamp: date, type: .pomodoroCompleted))
        finishPomodoro(intention: pomodoro.currentIntention)
    }

    private func finishPomodoro(intention: String?) {
        stopTickLoop()
        statusItem.button?.image = MenuBarRingIcon.idle
        refreshMenuVisibility()
        guard let intention else { return }
        checkInPanel.present(intention: intention) { [weak self] answer in
            self?.recordCheckIn(answer)
        }
    }

    private func recordCheckIn(_ answer: CheckInPanel.Answer) {
        let type: EventType
        switch answer {
        case .done: type = .checkInDone
        case .notDone: type = .checkInNotDone
        case .skipped: type = .checkInSkipped
        }
        write(LogEntry(timestamp: Date(), type: type))
        refreshSummary()
        if todayWindow?.window.isVisible == true {
            todayWindow.refresh()
        }
    }

    // MARK: - Menu / icon updates

    private func refreshMenuVisibility() {
        let running = pomodoro.isRunning
        intentionItem.isHidden = !running
        remainingItem.isHidden = !running
        endEarlyItem.isHidden = !running
        runningSeparator.isHidden = !running
        promptNowItem.isHidden = running
    }

    private func refreshSummary() {
        let entries = (try? log.readAll()) ?? []
        let anchor = DailyAnchor.mostRecent(
            onOrBefore: Date(),
            hour: settings.dailyResetHour
        )
        let summary = DailySummary.compute(from: entries, since: anchor)
        summaryItem.title = summary.headline
    }

    private func refreshLiveLabels(now: Date) {
        guard let remaining = pomodoro.remaining(at: now),
              let fraction = pomodoro.elapsedFraction(at: now),
              let intention = pomodoro.currentIntention else {
            return
        }
        intentionItem.title = intention
        remainingItem.title = format(remaining: remaining)
        statusItem.button?.image = MenuBarRingIcon.image(fraction: fraction)
    }

    private func format(remaining: TimeInterval) -> String {
        let total = Int(remaining.rounded(.up))
        let mm = total / 60
        let ss = total % 60
        return String(format: "%d:%02d remaining", mm, ss)
    }

    // MARK: - Utility

    private func write(_ entry: LogEntry) {
        do {
            try log.append(entry)
        } catch {
            NSLog("Intentional: failed to log \(entry.type.rawValue): \(error)")
        }
    }

    @objc private func revealLog() {
        NSWorkspace.shared.activateFileViewerSelecting([log.fileURL])
    }

    @objc private func openSettings() {
        settingsWindow.show()
    }

    @objc private func openToday() {
        todayWindow.show()
    }

    // MARK: - NSMenuDelegate

    nonisolated func menuWillOpen(_ menu: NSMenu) {
        MainActor.assumeIsolated { self.refreshSummary() }
    }
}
