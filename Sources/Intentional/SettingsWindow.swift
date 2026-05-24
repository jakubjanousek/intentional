import AppKit

@MainActor
final class SettingsWindow {
    let window: NSWindow
    var onChange: (() -> Void)?

    private var settings = Settings()

    private let pomodoroStepper = NSStepper()
    private let debounceStepper = NSStepper()
    private let dailyResetStepper = NSStepper()
    private let pomodoroValueLabel = NSTextField(labelWithString: "")
    private let debounceValueLabel = NSTextField(labelWithString: "")
    private let dailyResetValueLabel = NSTextField(labelWithString: "")

    init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 220),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Intentional Settings"
        window.isReleasedWhenClosed = false

        let pomodoroRow = makeRow(
            label: "Pomodoro length",
            stepper: pomodoroStepper,
            range: Settings.pomodoroRange,
            increment: 5,
            valueLabel: pomodoroValueLabel,
            action: #selector(didChangePomodoro)
        )
        let debounceRow = makeRow(
            label: "Prompt only after lock of",
            stepper: debounceStepper,
            range: Settings.debounceRange,
            increment: 1,
            valueLabel: debounceValueLabel,
            action: #selector(didChangeDebounce)
        )
        let dailyResetRow = makeRow(
            label: "Daily reset hour",
            stepper: dailyResetStepper,
            range: Settings.dailyResetRange,
            increment: 1,
            valueLabel: dailyResetValueLabel,
            action: #selector(didChangeDailyReset)
        )

        let stack = NSStackView(views: [pomodoroRow, debounceRow, dailyResetRow])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24),
            pomodoroRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            debounceRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            dailyResetRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
        window.contentView = container

        syncFromSettings()
    }

    func show() {
        syncFromSettings()
        if !window.isVisible {
            window.center()
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeRow(
        label: String,
        stepper: NSStepper,
        range: ClosedRange<Int>,
        increment: Int,
        valueLabel: NSTextField,
        action: Selector
    ) -> NSStackView {
        let titleLabel = NSTextField(labelWithString: label)
        titleLabel.font = NSFont.systemFont(ofSize: 13)
        titleLabel.textColor = .labelColor

        stepper.minValue = Double(range.lowerBound)
        stepper.maxValue = Double(range.upperBound)
        stepper.increment = Double(increment)
        stepper.valueWraps = false
        stepper.target = self
        stepper.action = action

        valueLabel.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.alignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.widthAnchor.constraint(equalToConstant: 72).isActive = true

        let trailing = NSStackView(views: [valueLabel, stepper])
        trailing.orientation = .horizontal
        trailing.spacing = 8
        trailing.alignment = .centerY

        let row = NSStackView(views: [titleLabel, NSView(), trailing])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        return row
    }

    private func syncFromSettings() {
        pomodoroStepper.integerValue = settings.pomodoroMinutes
        debounceStepper.integerValue = settings.debounceMinutes
        dailyResetStepper.integerValue = settings.dailyResetHour
        refreshLabels()
    }

    private func refreshLabels() {
        pomodoroValueLabel.stringValue = "\(settings.pomodoroMinutes) min"
        debounceValueLabel.stringValue = "\(settings.debounceMinutes) min"
        dailyResetValueLabel.stringValue = String(format: "%02d:00", settings.dailyResetHour)
    }

    @objc private func didChangePomodoro() {
        settings.pomodoroMinutes = pomodoroStepper.integerValue
        refreshLabels()
        onChange?()
    }

    @objc private func didChangeDebounce() {
        settings.debounceMinutes = debounceStepper.integerValue
        refreshLabels()
        onChange?()
    }

    @objc private func didChangeDailyReset() {
        settings.dailyResetHour = dailyResetStepper.integerValue
        refreshLabels()
        onChange?()
    }
}
