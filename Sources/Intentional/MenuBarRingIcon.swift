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

    static func resting(fraction: Double) -> NSImage {
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
            let outerRadius = min(bounds.width, bounds.height) / 2

            let ring = NSBezierPath(ovalIn: bounds)
            ring.lineWidth = lineWidth
            NSColor.black.setStroke()
            ring.stroke()

            let maxDotRadius = outerRadius * 0.55
            let dotRadius = maxDotRadius * (1 - clamped)
            if dotRadius > 0.5 {
                let dotRect = NSRect(
                    x: center.x - dotRadius,
                    y: center.y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )
                let dot = NSBezierPath(ovalIn: dotRect)
                NSColor.black.setFill()
                dot.fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    static var idle: NSImage { image(fraction: 0) }
}
