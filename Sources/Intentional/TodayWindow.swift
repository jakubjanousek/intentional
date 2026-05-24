import AppKit

@MainActor
final class TodayWindow {
    let window: NSWindow
    private let log: EventLog
    private let settings: () -> Settings

    private let header = NSTextField(labelWithString: "")
    private let rowsStack = NSStackView()
    private let emptyState = NSTextField(labelWithString: "Nothing logged today yet.")
    private let footer = NSTextField(labelWithString: "")
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    init(log: EventLog, settingsProvider: @escaping () -> Settings) {
        self.log = log
        self.settings = settingsProvider

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 360),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Today"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 360, height: 240)

        header.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        header.textColor = .secondaryLabelColor

        rowsStack.orientation = .vertical
        rowsStack.alignment = .leading
        rowsStack.spacing = 8
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        emptyState.font = NSFont.systemFont(ofSize: 13)
        emptyState.textColor = .tertiaryLabelColor

        footer.font = NSFont.systemFont(ofSize: 12)
        footer.textColor = .tertiaryLabelColor

        let topStack = NSStackView(views: [header, rowsStack, emptyState, footer])
        topStack.orientation = .vertical
        topStack.alignment = .leading
        topStack.spacing = 16
        topStack.translatesAutoresizingMaskIntoConstraints = false

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let flipped = FlippedView()
        flipped.translatesAutoresizingMaskIntoConstraints = false
        flipped.addSubview(topStack)
        NSLayoutConstraint.activate([
            topStack.leadingAnchor.constraint(equalTo: flipped.leadingAnchor, constant: 24),
            topStack.trailingAnchor.constraint(equalTo: flipped.trailingAnchor, constant: -24),
            topStack.topAnchor.constraint(equalTo: flipped.topAnchor, constant: 20),
            topStack.bottomAnchor.constraint(lessThanOrEqualTo: flipped.bottomAnchor, constant: -20),
            rowsStack.widthAnchor.constraint(equalTo: topStack.widthAnchor),
        ])

        scroll.documentView = flipped
        window.contentView = scroll
        NSLayoutConstraint.activate([
            flipped.widthAnchor.constraint(equalTo: scroll.widthAnchor),
        ])
    }

    func show() {
        refresh()
        if !window.isVisible {
            window.center()
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func refresh() {
        let now = Date()
        header.stringValue = dateFormatter.string(from: now).lowercased()

        let entries = (try? log.readAll()) ?? []
        let anchor = DailyAnchor.mostRecent(
            onOrBefore: now,
            hour: settings().dailyResetHour
        )
        let items = TodayLog.intentions(from: entries, since: anchor)
        let summary = DailySummary.compute(from: entries, since: anchor)

        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        emptyState.isHidden = !items.isEmpty
        rowsStack.isHidden = items.isEmpty

        for item in items {
            rowsStack.addArrangedSubview(makeRow(for: item))
        }
        if let last = rowsStack.arrangedSubviews.last {
            NSLayoutConstraint.activate([
                last.widthAnchor.constraint(equalTo: rowsStack.widthAnchor),
            ])
        }

        let footerText = makeFooter(focus: summary.focusSeconds, rest: summary.breakSeconds)
        footer.stringValue = footerText ?? ""
        footer.isHidden = footerText == nil
    }

    private func makeFooter(focus: TimeInterval, rest: TimeInterval) -> String? {
        var parts: [String] = []
        if focus >= 60 { parts.append("\(formatMinutes(focus)) focused") }
        if rest >= 60 { parts.append("\(formatMinutes(rest)) on break") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func formatMinutes(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours == 0 { return "\(mins)m" }
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h \(mins)m"
    }

    private func makeRow(for item: TodaysIntention) -> NSView {
        let glyph = NSTextField(labelWithString: glyphCharacter(for: item.outcome))
        glyph.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        glyph.textColor = glyphColor(for: item.outcome)
        glyph.translatesAutoresizingMaskIntoConstraints = false
        glyph.widthAnchor.constraint(equalToConstant: 18).isActive = true

        let text = NSTextField(labelWithString: item.intention)
        text.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        text.textColor = .labelColor
        text.lineBreakMode = .byTruncatingTail

        let time = NSTextField(labelWithString: timeFormatter.string(from: item.startedAt).lowercased())
        time.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        time.textColor = .tertiaryLabelColor
        time.alignment = .right
        time.translatesAutoresizingMaskIntoConstraints = false
        time.widthAnchor.constraint(equalToConstant: 72).isActive = true

        let row = NSStackView(views: [glyph, text, NSView(), time])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        return row
    }

    private func glyphCharacter(for outcome: TodaysIntention.Outcome) -> String {
        switch outcome {
        case .done: return "✓"
        case .notDone: return "✗"
        case .skipped: return "·"
        case .inProgress: return "◐"
        }
    }

    private func glyphColor(for outcome: TodaysIntention.Outcome) -> NSColor {
        switch outcome {
        case .inProgress:
            return NSColor.systemOrange
        case .skipped:
            return .tertiaryLabelColor
        case .done, .notDone:
            return .secondaryLabelColor
        }
    }
}

private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
