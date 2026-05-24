# Intentional

A personal macOS menu-bar app. Unlock your Mac, get a soft-nudge prompt
asking *"what are you about to do?"*, type one thing, and an
auto-pomodoro starts. Skipping is fine — skips are data.

This is a learn-macOS project as much as a productivity tool. The README
exists so future-me can pick this back up after a gap; it's not a pitch.

## Status

Early. The unlock prompt is wired and logging works. No pomodoro timer
yet, no end-of-timer check-in, no insights.

What works today:
- Menu-bar app (accessory mode, no Dock icon)
- Lock / unlock detection via `com.apple.screenIs(Locked|Unlocked)`
- Debounced unlock prompt — only fires if locked >5 min, or on the first
  unlock after 4am local
- Translucent `NSPanel` with a monospaced text field, `↵` to start,
  `esc` to skip
- JSONL event log at `~/Library/Application Support/Intentional/events.log`
- Menu items: **Prompt Now** (test the panel without locking),
  **Reveal Log in Finder**, **Quit**

## Run

```sh
swift run
```

Then look for the `○` in the menu bar. To exercise the panel without
locking the screen, click the icon and pick **Prompt Now**.

Tests:

```sh
swift test
```

## Where things live

```
Sources/Intentional/
  main.swift                  bootstraps NSApplication
  AppDelegate.swift           menu bar + composes monitor/gate/panel/log
  UnlockMonitor.swift         distributed-notification observer
  UnlockGate.swift            debounce + daily-anchor decision (pure)
  IntentionPromptPanel.swift  HUD NSPanel with field + Start/Skip
  EventLog.swift              JSONL append-only log

Tests/IntentionalTests/
  EventLogTests.swift         format + append
  UnlockGateTests.swift       prompt-decision cases

docs/ideas/intentional.md     product one-pager (problem, MVP, visual)
```

## Event log

Append-only JSONL. One line per event. Current shape:

```
{"ts":"2026-05-24T19:56:47Z","type":"started"}
{"ts":"2026-05-24T20:14:02Z","type":"unlock"}
{"ts":"2026-05-24T20:14:02Z","type":"prompted"}
{"ts":"2026-05-24T20:14:11Z","type":"intention","intention":"write tests"}
```

Event types: `started`, `unlock`, `lock`, `prompted`, `intention`,
`skipped`.

## Roadmap (rough)

1. 25-min pomodoro timer + menu-bar ring icon that fills clockwise
2. End-of-pomodoro check-in card ("did you do it?")
3. Settings pane (timer length, debounce window, auto-start)
4. Launch at login
5. Pattern surfacing — *after* there's >2 weeks of data

Anything labelled "Phase 2" in `docs/ideas/intentional.md` stays out.

## Build environment notes

- Requires macOS 14+, Swift 6 toolchain
- `swift-testing` is declared as a package dep because the bare
  Command Line Tools toolchain doesn't bundle it. Full Xcode ships it
  natively; once that's installed, the dep can be dropped from
  `Package.swift`.
