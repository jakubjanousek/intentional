import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let log = EventLog(fileURL: EventLog.defaultLocation())
    private var statusItem: NSStatusItem!
    private var unlockMonitor: UnlockMonitor!
    private var promptPanel: IntentionPromptPanel!
    private var gate = UnlockGate()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "○"
            button.toolTip = "Intentional"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Prompt Now",
            action: #selector(promptNow),
            keyEquivalent: "p"
        ))
        menu.addItem(NSMenuItem(
            title: "Reveal Log in Finder",
            action: #selector(revealLog),
            keyEquivalent: "l"
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit Intentional",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        statusItem.menu = menu

        promptPanel = IntentionPromptPanel()

        unlockMonitor = UnlockMonitor()
        unlockMonitor.onUnlock = { [weak self] date in self?.handleUnlock(at: date) }
        unlockMonitor.onLock = { [weak self] date in self?.handleLock(at: date) }
        unlockMonitor.start()

        write(LogEntry(timestamp: Date(), type: .started))
    }

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
        promptPanel.present(
            onStart: { [weak self] intention in
                self?.write(LogEntry(timestamp: Date(), type: .intention, intention: intention))
            },
            onSkip: { [weak self] in
                self?.write(LogEntry(timestamp: Date(), type: .skipped))
            }
        )
    }

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
}
