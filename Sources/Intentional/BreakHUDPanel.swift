import AppKit

@MainActor
final class BreakHUDPanel: NSPanel {
    private let titleLabel = NSTextField(labelWithString: "ON BREAK")
    private let subtitleLabel = NSTextField(labelWithString: "step away — relax")
    private let countdownLabel = NSTextField(labelWithString: "")
    private let endButton: NSButton
    private let failedButton: NSButton
    private var onEndEarly: (() -> Void)?
    private var onMarkFailed: (() -> Void)?

    init() {
        endButton = NSButton(title: "End early", target: nil, action: nil)
        failedButton = NSButton(title: "Failed", target: nil, action: nil)

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 80),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        hidesOnDeactivate = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        let backdrop = NSVisualEffectView()
        backdrop.material = .hudWindow
        backdrop.state = .active
        backdrop.blendingMode = .behindWindow
        backdrop.wantsLayer = true
        backdrop.layer?.cornerRadius = 14
        backdrop.layer?.masksToBounds = true
        backdrop.layer?.borderWidth = 1
        backdrop.layer?.borderColor = NSColor.systemGreen.withAlphaComponent(0.55).cgColor
        contentView = backdrop

        titleLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = NSColor.systemGreen

        subtitleLabel.font = NSFont.systemFont(ofSize: 11)
        subtitleLabel.textColor = .secondaryLabelColor

        countdownLabel.font = NSFont.monospacedSystemFont(ofSize: 26, weight: .regular)
        countdownLabel.textColor = .labelColor

        endButton.target = self
        endButton.action = #selector(didTapEndEarly)
        endButton.bezelStyle = .rounded
        endButton.controlSize = .small

        failedButton.target = self
        failedButton.action = #selector(didTapFailed)
        failedButton.bezelStyle = .rounded
        failedButton.controlSize = .small

        let leftStack = NSStackView(views: [titleLabel, subtitleLabel])
        leftStack.orientation = .vertical
        leftStack.alignment = .leading
        leftStack.spacing = 2

        let buttons = NSStackView(views: [failedButton, endButton])
        buttons.orientation = .horizontal
        buttons.spacing = 6

        let stack = NSStackView(views: [countdownLabel, leftStack, NSView(), buttons])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        backdrop.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor, constant: 18 * -1),
            stack.topAnchor.constraint(equalTo: backdrop.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: backdrop.bottomAnchor, constant: -14),
        ])
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func show(
        remaining: TimeInterval,
        onEndEarly: @escaping () -> Void,
        onMarkFailed: @escaping () -> Void
    ) {
        self.onEndEarly = onEndEarly
        self.onMarkFailed = onMarkFailed
        resetFailedButton()
        updateRemaining(remaining)
        positionTopCenter()
        orderFrontRegardless()
    }

    func updateRemaining(_ remaining: TimeInterval) {
        let total = max(0, Int(remaining.rounded(.up)))
        let mm = total / 60
        let ss = total % 60
        countdownLabel.stringValue = String(format: "%d:%02d", mm, ss)
    }

    func showAsFailed() {
        failedButton.title = "Marked failed"
        failedButton.isEnabled = false
    }

    func dismiss() {
        onEndEarly = nil
        onMarkFailed = nil
        orderOut(nil)
    }

    private func resetFailedButton() {
        failedButton.title = "Failed"
        failedButton.isEnabled = true
    }

    @objc private func didTapEndEarly() {
        onEndEarly?()
    }

    @objc private func didTapFailed() {
        onMarkFailed?()
    }

    private func positionTopCenter() {
        guard let screen = NSScreen.main else { center(); return }
        let visible = screen.visibleFrame
        let size = frame.size
        let margin: CGFloat = 12
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.maxY - size.height - margin
        )
        setFrameOrigin(origin)
    }
}
