import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let log = EventLog(fileURL: EventLog.defaultLocation())
    private var statusItem: NSStatusItem!
    private var unlockMonitor: UnlockMonitor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "○"
            button.toolTip = "Intentional"
        }

        let menu = NSMenu()
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

        unlockMonitor = UnlockMonitor(log: log)
        unlockMonitor.start()

        try? log.append(LogEntry(timestamp: Date(), type: .started))
    }

    @objc private func revealLog() {
        NSWorkspace.shared.activateFileViewerSelecting([log.fileURL])
    }
}
