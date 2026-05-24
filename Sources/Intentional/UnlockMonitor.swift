import AppKit

@MainActor
final class UnlockMonitor {
    var onUnlock: ((Date) -> Void)?
    var onLock: ((Date) -> Void)?

    private var observers: [NSObjectProtocol] = []

    func start() {
        let center = DistributedNotificationCenter.default()
        observers.append(center.addObserver(
            forName: .init("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.onUnlock?(Date()) }
        })
        observers.append(center.addObserver(
            forName: .init("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.onLock?(Date()) }
        })
    }
}
