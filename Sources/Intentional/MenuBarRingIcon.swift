import AppKit

enum MenuBarRingIcon {
    static let size: CGFloat = 18

    static func image(fraction: Double) -> NSImage {
        let clamped = max(0, min(1, fraction))
        let dimension = size
        let image = NSImage(
            size: NSSize(width: dimension, height: dimension),
            flipped: false
        ) { rect in
            let lineWidth: CGFloat = 1.6
            let inset: CGFloat = lineWidth / 2 + 1
            let bounds = rect.insetBy(dx: inset, dy: inset)
            let center = NSPoint(x: bounds.midX, y: bounds.midY)
            let radius = min(bounds.width, bounds.height) / 2

            let backdrop = NSBezierPath(ovalIn: bounds)
            backdrop.lineWidth = lineWidth
            NSColor.black.withAlphaComponent(0.25).setStroke()
            backdrop.stroke()

            if clamped > 0 {
                let startAngle: CGFloat = 90
                let endAngle = startAngle - CGFloat(clamped) * 360
                let arc = NSBezierPath()
                arc.appendArc(
                    withCenter: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: true
                )
                arc.lineWidth = lineWidth
                arc.lineCapStyle = .round
                NSColor.black.setStroke()
                arc.stroke()
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    static var idle: NSImage { image(fraction: 0) }
}
