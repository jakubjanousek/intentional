import AppKit

@MainActor
final class CheckInPanel: NSPanel {
    private let promptLabel: NSTextField
    private let intentionLabel: NSTextField
    private var onAnswer: ((Answer) -> Void)?

    enum Answer {
        case done
        case notDone
        case skipped
    }

    init() {
        self.promptLabel = NSTextField(labelWithString: "How'd that go?")
        self.intentionLabel = NSTextField(labelWithString: "")

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 120),
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
        contentView = backdrop

        promptLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        promptLabel.textColor = .secondaryLabelColor

        intentionLabel.font = NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        intentionLabel.lineBreakMode = .byTruncatingTail
        intentionLabel.maximumNumberOfLines = 1

        let noButton = NSButton(title: "Not really", target: self, action: #selector(didTapNotDone))
        noButton.bezelStyle = .rounded

        let yesButton = NSButton(title: "Done", target: self, action: #selector(didTapDone))
        yesButton.bezelStyle = .rounded
        yesButton.keyEquivalent = "\r"

        let buttons = NSStackView(views: [noButton, yesButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8

        let textStack = NSStackView(views: [promptLabel, intentionLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4

        let footer = NSStackView(views: [NSView(), buttons])
        footer.orientation = .horizontal
        footer.alignment = .centerY

        let stack = NSStackView(views: [textStack, footer])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        backdrop.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: backdrop.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: backdrop.bottomAnchor, constant: -18),
            textStack.widthAnchor.constraint(equalTo: stack.widthAnchor),
            footer.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func present(intention: String, onAnswer: @escaping (Answer) -> Void) {
        self.onAnswer = onAnswer
        intentionLabel.stringValue = intention
        positionTopRight()
        orderFrontRegardless()
    }

    @objc private func didTapDone() { deliver(.done) }
    @objc private func didTapNotDone() { deliver(.notDone) }

    private func deliver(_ answer: Answer) {
        let callback = onAnswer
        onAnswer = nil
        orderOut(nil)
        callback?(answer)
    }

    private func positionTopRight() {
        guard let screen = NSScreen.main else { center(); return }
        let visible = screen.visibleFrame
        let size = frame.size
        let margin: CGFloat = 16
        let origin = NSPoint(
            x: visible.maxX - size.width - margin,
            y: visible.maxY - size.height - margin
        )
        setFrameOrigin(origin)
    }
}
