import AppKit
import CoreGraphics

@MainActor
final class IdleMonitor {
    var threshold: TimeInterval = 10 * 60
    var pollInterval: TimeInterval = 30

    var onIdleStarted: ((Date) -> Void)?
    var onIdleEnded: ((Date) -> Void)?

    private var timer: Timer?
    private var isIdle = false
    private var isPaused = false

    func start() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func pause() {
        isPaused = true
        isIdle = false
    }

    func resume() {
        isPaused = false
        isIdle = false
    }

    private func poll() {
        guard !isPaused else { return }
        let idleSeconds = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInputEvent)
        let now = Date()
        if !isIdle, idleSeconds >= threshold {
            isIdle = true
            onIdleStarted?(now.addingTimeInterval(-idleSeconds))
        } else if isIdle, idleSeconds < pollInterval {
            isIdle = false
            onIdleEnded?(now)
        }
    }

    private var anyInputEvent: CGEventType {
        CGEventType(rawValue: ~0) ?? .null
    }
}
