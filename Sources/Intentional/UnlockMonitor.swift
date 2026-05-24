import AppKit

@MainActor
final class UnlockMonitor {
    private let log: EventLog
    private var observers: [NSObjectProtocol] = []

    init(log: EventLog) {
        self.log = log
    }

    func start() {
        let center = DistributedNotificationCenter.default()
        observers.append(center.addObserver(
            forName: .init("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.record(.unlock) }
        })
        observers.append(center.addObserver(
            forName: .init("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.record(.lock) }
        })
    }

    private func record(_ type: EventType) {
        do {
            try log.append(LogEntry(timestamp: Date(), type: type))
        } catch {
            NSLog("Intentional: failed to log \(type): \(error)")
        }
    }
}
