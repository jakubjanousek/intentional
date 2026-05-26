import AppKit

@MainActor
final class TodayWindow {
    let window: NSWindow
    var onChange: (() -> Void)?
    private let log: EventLog
    private let settings: () -> Settings

    private let header = NSTextField(labelWithString: "")
    private let weekStack = NSStackView()
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
    private let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
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

        weekStack.orientation = .horizontal
        weekStack.alignment = .top
        weekStack.distribution = .fillEqually
        weekStack.spacing = 6
        weekStack.translatesAutoresizingMaskIntoConstraints = false

        rowsStack.orientation = .vertical
        rowsStack.alignment = .leading
        rowsStack.spacing = 8
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        emptyState.font = NSFont.systemFont(ofSize: 13)
        emptyState.textColor = .tertiaryLabelColor

        footer.font = NSFont.systemFont(ofSize: 12)
        footer.textColor = .tertiaryLabelColor

        let topStack = NSStackView(views: [header, weekStack, rowsStack, emptyState, footer])
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
            weekStack.widthAnchor.constraint(equalTo: topStack.widthAnchor),
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
        let resetHour = settings().dailyResetHour
        let anchor = DailyAnchor.mostRecent(
            onOrBefore: now,
            hour: resetHour
        )
        let items = TodayLog.intentions(from: entries, since: anchor)
        let summary = DailySummary.compute(from: entries, since: anchor)
        let week = RecentDays.summaries(
            from: entries,
            endingOn: now,
            days: 7,
            dailyResetHour: resetHour
        )
        rebuildWeekStack(stats: week, todayAnchor: anchor)

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

        let footerText = makeFooter(summary: summary)
        footer.stringValue = footerText ?? ""
        footer.isHidden = footerText == nil
    }

    private func rebuildWeekStack(stats: [DayStat], todayAnchor: Date) {
        weekStack.arrangedSubviews.forEach {
            weekStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for stat in stats {
            weekStack.addArrangedSubview(makeWeekCell(stat: stat, isToday: stat.anchor == todayAnchor))
        }
    }

    private func makeWeekCell(stat: DayStat, isToday: Bool) -> NSView {
        let isCurrent = isToday
        let baseColor: NSColor = isCurrent ? .labelColor : .secondaryLabelColor
        let dimColor: NSColor = isCurrent ? .secondaryLabelColor : .tertiaryLabelColor

        let day = NSTextField(labelWithString: weekdayFormatter.string(from: stat.anchor).lowercased())
        day.font = NSFont.monospacedSystemFont(ofSize: 11, weight: isCurrent ? .semibold : .regular)
        day.textColor = baseColor
        day.alignment = .center

        let focusText: String = stat.focusSeconds >= 60 ? formatMinutesCompact(stat.focusSeconds) : "—"
        let focus = NSTextField(labelWithString: focusText)
        focus.font = NSFont.monospacedSystemFont(ofSize: 12, weight: isCurrent ? .semibold : .regular)
        focus.textColor = stat.focusSeconds >= 60 ? baseColor : dimColor
        focus.alignment = .center

        let dots = NSTextField(labelWithString: dotString(for: stat.intentionsDone))
        dots.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        dots.textColor = stat.intentionsDone > 0 ? NSColor.systemGreen : dimColor
        dots.alignment = .center

        let column = NSStackView(views: [day, focus, dots])
        column.orientation = .vertical
        column.alignment = .centerX
        column.spacing = 2
        return column
    }

    private func formatMinutesCompact(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours == 0 { return "\(mins)m" }
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h\(mins)"
    }

    private func dotString(for count: Int) -> String {
        if count <= 0 { return "·" }
        if count <= 4 { return String(repeating: "●", count: count) }
        return "●●●●+"
    }

    private func makeFooter(summary: DailySummary) -> String? {
        var parts: [String] = []
        if summary.focusSecondsSuccessful >= 60 {
            parts.append("\(formatMinutes(summary.focusSecondsSuccessful)) successful focus")
        }
        let abandoned = summary.focusSeconds - summary.focusSecondsSuccessful
        if abandoned >= 60 {
            parts.append("\(formatMinutes(abandoned)) abandoned")
        }
        if summary.breakSecondsBetweenPomodoros >= 60 {
            parts.append("\(formatMinutes(summary.breakSecondsBetweenPomodoros)) on break")
        }
        if summary.activeSecondsOffFocus >= 60 {
            parts.append("\(formatMinutes(summary.activeSecondsOffFocus)) off-focus")
        }
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
        row.menu = makeContextMenu(for: item)
        return row
    }

    private func makeContextMenu(for item: TodaysIntention) -> NSMenu {
        let menu = NSMenu()
        let startedAt = item.startedAt
        let done = ClosureMenuItem(title: "Mark done") { [weak self] in
            self?.setOutcome(.outcomeDone, forIntentionAt: startedAt)
        }
        done.state = item.outcome == .done ? .on : .off
        menu.addItem(done)

        let failed = ClosureMenuItem(title: "Mark failed") { [weak self] in
            self?.setOutcome(.outcomeFailed, forIntentionAt: startedAt)
        }
        failed.state = item.outcome == .failed ? .on : .off
        menu.addItem(failed)

        let skipped = ClosureMenuItem(title: "Mark skipped") { [weak self] in
            self?.setOutcome(.outcomeSkipped, forIntentionAt: startedAt)
        }
        skipped.state = item.outcome == .skipped ? .on : .off
        menu.addItem(skipped)

        menu.addItem(.separator())

        let delete = ClosureMenuItem(title: "Delete") { [weak self] in
            self?.deleteIntention(at: item.startedAt)
        }
        menu.addItem(delete)
        return menu
    }

    private func setOutcome(_ type: EventType, forIntentionAt startedAt: Date) {
        do {
            let entries = try log.readAll()
            let mutated = TodayLog.setOutcome(
                intentionAt: startedAt,
                to: type,
                timestamp: Date(),
                in: entries
            )
            try log.rewrite(mutated)
        } catch {
            NSLog("Intentional: failed to set outcome \(type.rawValue): \(error)")
            return
        }
        onChange?()
        refresh()
    }

    private func deleteIntention(at startedAt: Date) {
        do {
            let entries = try log.readAll()
            let mutated = TodayLog.deleteIntention(at: startedAt, in: entries)
            try log.rewrite(mutated)
        } catch {
            NSLog("Intentional: failed to delete intention: \(error)")
            return
        }
        onChange?()
        refresh()
    }

    private func glyphCharacter(for outcome: TodaysIntention.Outcome) -> String {
        switch outcome {
        case .done: return "✓"
        case .failed: return "✗"
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
        case .done, .failed:
            return .secondaryLabelColor
        }
    }
}

private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

private final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(title: String, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(invoke), keyEquivalent: "")
        target = self
    }

    required init(coder: NSCoder) { fatalError() }

    @objc private func invoke() { handler() }
}
