# Intentional — Mac focus app

## Problem Statement
How might we turn the moment of unlocking the Mac into a small commitment
ritual that names what you're about to do — and quietly notice, over time,
when those commitments don't match reality?

## Recommended Direction
A menu-bar Mac app that intercepts unlock events with a soft-nudge prompt:
"What are you about to do?" Typing an intention auto-starts a 25-minute
pomodoro and pins the intention in the menu bar. At the end of the timer,
a single tap logs "done / not done." Skipping the prompt is allowed but
recorded.

Over time, a quiet intelligence layer surfaces patterns with *variable
salience* — mostly silent, occasionally a hard mirror ("You set 'email' as
the intention 5x this week and skipped the timer every time"). This is the
piece that makes it survive past week two, where pure pomodoro apps decay
into wallpaper for you.

Two non-obvious design calls:
- **Pomodoro on by default**, with a setting to make it opt-in per
  intention. Matches "pomodoros work for me sometimes" without forcing the
  ceremony in v0.
- **Soft nudge, not hard block.** Skip is always available; skips are data.

## Key Assumptions to Validate
- [ ] You'll keep using it past week 2 — validate by checking your own
      skip rate at day 14. If you're skipping >70%, the prompt is wallpaper.
- [ ] The intention input stays specific, not "stuff" / "work" — validate
      by reading back your own log after week 1.
- [ ] Pattern-surfacing reads as honest mirror, not guilt — validate by
      drafting 5 example insights *before* coding the algorithm and
      checking which ones feel useful vs. annoying.
- [ ] Unlock prompt frequency feels right — don't prompt on every micro-
      unlock (60-sec coffee break). Needs a debounce rule (e.g. only
      prompt after N minutes locked, or on first unlock of day).

## MVP Scope
**In:**
- Detect unlock via `NSDistributedNotificationCenter`
  (`com.apple.screenIsUnlocked`)
- Soft-nudge panel (`NSPanel`) with text field + Skip button
- Auto-start 25-min pomodoro on submit; intention pinned in menu bar
  (`NSStatusItem`)
- End-of-timer prompt: "did you do it?" (Y/N) — single tap
- Local log of (timestamp, intention, completed?, skipped?) in SQLite or
  JSON
- Settings pane: timer length, debounce window, auto-start on/off
- Launch-at-login + standard menu-bar app conventions

**Out (Phase 2):**
- Pattern surfacing / insights (need ≥2 weeks of data first)
- Voice intention input
- Calendar-aware intention proposals
- Intention → app/workspace launch
- Accountability partner / multiplayer
- Cross-device sync

## Not Doing (and Why)
- **Hard block on unlock** — punitive tools (Freedom, Cold Turkey) didn't
  stick for you; replicating that pattern would replicate the failure.
- **Insights in v0** — surfacing patterns before there's enough data
  produces noise. Ship the logger first, earn the right to advise later.
- **App Store distribution** — success criteria is "use it + learn macOS,"
  not "ship to users." Sandbox/notarization headaches can wait.
- **AI/LLM-powered insights** — rule-based pattern detection is enough for
  v1 and keeps the app fully local, fast, and offline.
- **One-week manual validation first** — you've made the call to build.
  Settings escape hatch is the reversibility plan.

## Open Questions
- Debounce rule for "what counts as an unlock worth prompting?" — first
  guess: only if locked >5 min, or first unlock after 4am.
- Storage: SQLite (overkill, but right shape for later analytics) or JSON
  (simplest)? Lean SQLite if you want to learn it; JSON otherwise.
- AppKit vs. SwiftUI for the unlock panel? SwiftUI works but `NSPanel`
  hosting is fiddlier — AppKit might teach you more of the platform.
- What's the right tone for the end-of-timer prompt? "Done?" vs.
  "How'd that go?" — small wording choice with big behavioral pull.
