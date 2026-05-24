import AppKit

@MainActor
final class IntentionPromptPanel: NSPanel {
    private let textField: NSTextField
    private var onStart: ((String) -> Void)?
    private var onSkip: (() -> Void)?

    init() {
        let field = NSTextField()
        self.textField = field

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 200),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel, .closable],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
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
        backdrop.layer?.cornerRadius = 16
        backdrop.layer?.masksToBounds = true
        contentView = backdrop

        let prompt = NSTextField(labelWithString: "What are you about to do?")
        prompt.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        prompt.textColor = .secondaryLabelColor
        prompt.alignment = .left

        field.translatesAutoresizingMaskIntoConstraints = false
        field.font = monospacedFont(size: 20)
        field.placeholderString = "type one thing"
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.usesSingleLineMode = true
        field.lineBreakMode = .byTruncatingTail

        let skipButton = NSButton(
            title: "Skip",
            target: self,
            action: #selector(didTapSkip)
        )
        skipButton.bezelStyle = .rounded
        skipButton.keyEquivalent = "\u{1b}"

        let startButton = NSButton(
            title: "Start",
            target: self,
            action: #selector(didTapStart)
        )
        startButton.bezelStyle = .rounded
        startButton.keyEquivalent = "\r"

        let buttons = NSStackView(views: [skipButton, startButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.alignment = .centerY
        buttons.distribution = .fill

        let hint = NSTextField(labelWithString: "↵ start  ·  esc skip")
        hint.font = NSFont.systemFont(ofSize: 11)
        hint.textColor = .tertiaryLabelColor

        let footer = NSStackView(views: [hint, NSView(), buttons])
        footer.orientation = .horizontal
        footer.alignment = .centerY
        footer.spacing = 12

        let stack = NSStackView(views: [prompt, field, footer])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        backdrop.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: backdrop.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: backdrop.bottomAnchor, constant: -24),
            field.widthAnchor.constraint(equalTo: stack.widthAnchor),
            footer.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func present(
        prefill: String? = nil,
        onStart: @escaping (String) -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.onStart = onStart
        self.onSkip = onSkip
        textField.stringValue = prefill ?? ""
        center()
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
        textField.window?.makeFirstResponder(textField)
        if prefill != nil {
            textField.currentEditor()?.selectAll(nil)
        }
    }

    @objc private func didTapStart() {
        let trimmed = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            NSSound.beep()
            return
        }
        let callback = onStart
        dismiss()
        callback?(trimmed)
    }

    @objc private func didTapSkip() {
        let callback = onSkip
        dismiss()
        callback?()
    }

    private func dismiss() {
        onStart = nil
        onSkip = nil
        orderOut(nil)
    }

    private func monospacedFont(size: CGFloat) -> NSFont {
        if let geist = NSFont(name: "GeistMono-Regular", size: size) {
            return geist
        }
        return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
}
