// Generate Intentional.iconset by drawing the app icon procedurally
// at every required size, then iconutil packs it into .icns.
//
// Run via: swift script/make-icon.swift <output-iconset-dir>
//
// Design: near-black rounded-rect tile with a cream ring centered.
// The ring echoes the menu-bar mark. No amber here — amber is
// reserved for "a pomodoro is currently running."

import AppKit

func draw(size pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let s = CGFloat(pixels)
    let bg = NSRect(x: 0, y: 0, width: s, height: s)
    let cornerRadius = s * 0.2237
    NSColor(srgbRed: 0.07, green: 0.07, blue: 0.08, alpha: 1.0).setFill()
    NSBezierPath(roundedRect: bg, xRadius: cornerRadius, yRadius: cornerRadius).fill()

    let inset = s * 0.22
    let ringRect = bg.insetBy(dx: inset, dy: inset)
    let lineWidth = max(2, s * 0.055)
    let ring = NSBezierPath(ovalIn: ringRect)
    ring.lineWidth = lineWidth
    ring.lineCapStyle = .round
    NSColor(srgbRed: 0.94, green: 0.93, blue: 0.90, alpha: 1.0).setStroke()
    ring.stroke()

    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("PNG encode failed at \(pixels)")
    }
    return data
}

guard CommandLine.arguments.count >= 2 else {
    fputs("usage: make-icon.swift <output-iconset-dir>\n", stderr)
    exit(64)
}

let iconset = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let specs: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for spec in specs {
    let data = draw(size: spec.pixels)
    try data.write(to: iconset.appendingPathComponent(spec.name))
}

print("→ iconset: \(iconset.path)")
