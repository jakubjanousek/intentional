import AppKit
import QuartzCore

@MainActor
enum ScreenBorderFlash {
    private static var windows: [NSWindow] = []

    static func flash(color: NSColor = .systemOrange, duration: CFTimeInterval = 2.0) {
        clear()
        for screen in NSScreen.screens {
            let window = makeWindow(for: screen, color: color)
            window.orderFrontRegardless()
            windows.append(window)
            animate(window: window, duration: duration)
        }
    }

    static func clear() {
        for window in windows { window.orderOut(nil) }
        windows.removeAll()
    }

    private static func makeWindow(for screen: NSScreen, color: NSColor) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.hasShadow = false
        window.isReleasedWhenClosed = false

        let bounds = NSRect(origin: .zero, size: screen.frame.size)
        let view = NSView(frame: bounds)
        view.wantsLayer = true

        let shape = CAShapeLayer()
        shape.frame = bounds
        let inset: CGFloat = 6
        let rect = bounds.insetBy(dx: inset, dy: inset)
        shape.path = CGPath(roundedRect: rect, cornerWidth: 22, cornerHeight: 22, transform: nil)
        shape.fillColor = NSColor.clear.cgColor
        shape.strokeColor = color.cgColor
        shape.lineWidth = 14
        shape.shadowColor = color.cgColor
        shape.shadowRadius = 24
        shape.shadowOpacity = 0.9
        shape.shadowOffset = .zero
        shape.opacity = 0

        view.layer?.addSublayer(shape)
        window.contentView = view
        return window
    }

    private static func animate(window: NSWindow, duration: CFTimeInterval) {
        guard let shape = window.contentView?.layer?.sublayers?.first else { return }
        let anim = CAKeyframeAnimation(keyPath: "opacity")
        anim.values = [0.0, 1.0, 1.0, 0.0]
        anim.keyTimes = [0.0, 0.12, 0.7, 1.0]
        anim.duration = duration
        shape.add(anim, forKey: "flash")
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) { [weak window] in
            window?.orderOut(nil)
        }
    }
}
