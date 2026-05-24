# Intentional

A personal macOS menu-bar app. Unlock your Mac, get a soft-nudge prompt
asking *"what are you about to do?"*, type one thing, and an
auto-pomodoro starts. Skipping is fine — skips are data.

This is a learn-macOS project as much as a productivity tool. The README
exists so future-me can pick this back up after a gap; it's not a pitch.

## Status

MVP complete and in daily use. No pattern-surfacing yet (deliberate —
need ≥2 weeks of real data first).

What works today:
- Menu-bar app (accessory mode, no Dock icon)
- Lock / unlock detection via `com.apple.screenIs(Locked|Unlocked)`
- Debounced unlock prompt — only fires if locked >5 min, or on the first
  unlock after the configurable daily reset hour (default 4am local)
- Translucent `NSPanel` with a monospaced text field, prefilled with
  your last intention; `↵` to start, `esc` to skip
- 25-min auto-pomodoro on submit, with a menu-bar ring icon that fills
  clockwise as it elapses
- End-of-pomodoro HUD card ("How'd that go?") with Done / Not really;
  auto-dismisses to *skipped* after 10s
- JSONL event log at `~/Library/Application Support/Intentional/events.log`
- "Today" summary in the menu — *3 intentions today · 2 done*
- Settings pane with timer length, debounce window, daily reset hour,
  and a Launch-at-login toggle
- Launch-at-login via `SMAppService` (requires running from the bundled
  `.app` — see below)

## Run

For quick iteration during dev:

```sh
swift run
```

Then look for the `○` in the menu bar. To exercise the panel without
locking the screen, click the icon and pick **Prompt Now**.

For daily use, build the `.app` bundle and launch from there — that's
what unlocks the "Launch at login" toggle in Settings:

```sh
./script/bundle.sh        # produces ./Intentional.app
open Intentional.app
```

The bundle is ad-hoc codesigned, so macOS Gatekeeper will let it run
locally but won't trust it on other machines. For daily use, drag
`Intentional.app` into `/Applications/` so the path stays stable
across rebuilds.

Tests:

```sh
swift test
```

## Where things live

```
Sources/Intentional/
  main.swift                  bootstraps NSApplication
  AppDelegate.swift           menu bar + composes everything
  UnlockMonitor.swift         distributed-notification observer
  UnlockGate.swift            debounce + daily-anchor decision (pure)
  DailyAnchor.swift           "most-recent N o'clock" calculation (pure)
  IntentionPromptPanel.swift  HUD NSPanel with field + Start/Skip
  PomodoroTimer.swift         pure idle→running→finished state machine
  MenuBarRingIcon.swift       NSImage with clockwise-filling arc
  CheckInPanel.swift          end-of-pomodoro Done/Not-really card
  EventLog.swift              JSONL append-only log + reader
  DailySummary.swift          today's counts + headline
  Settings.swift              UserDefaults-backed config
  SettingsWindow.swift        plain NSWindow with steppers
  LaunchAtLogin.swift         SMAppService wrapper

Tests/IntentionalTests/       Swift Testing — one file per component

script/
  bundle.sh                   wraps the SwiftPM binary in Intentional.app
  Info.plist                  bundle metadata (LSUIElement=true)

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
`skipped`, `pomodoro_completed`, `pomodoro_ended_early`,
`check_in_done`, `check_in_not_done`, `check_in_skipped`.

## Roadmap

MVP boxes (all checked):

- [x] Unlock detection + debounced soft-nudge panel
- [x] 25-min auto pomodoro with clockwise-filling ring icon
- [x] End-of-pomodoro check-in card
- [x] JSONL event log + today's summary in menu
- [x] Settings pane (timer length, debounce window, daily reset hour)
- [x] Launch at login (via the bundled `.app`)

Next, eventually:

- Pattern surfacing — *only* after >2 weeks of real data
- Polished installer / signed bundle if I ever want to share it

Anything labelled "Phase 2" in `docs/ideas/intentional.md` stays out.

## Build environment notes

- Requires macOS 14+, Swift 6 toolchain
- `swift-testing` is declared as a package dep because the bare
  Command Line Tools toolchain doesn't bundle it. Full Xcode ships it
  natively; once that's installed, the dep can be dropped from
  `Package.swift`.
