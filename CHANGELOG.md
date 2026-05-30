# Changelog

## 2.1.0

### Added
- **Preferences window** — set a custom global shortcut for each display and for
  next/previous cycling: click a recorder and press the keys you want
  (⎋ cancels, ⌫ clears).
- Bindings persist **per monitor**, keyed by the display's UUID, so they survive
  reconnects and reordering.
- **Identify Displays** flashes a large number on each screen so you can tell
  which is which.

### Changed
- Hotkeys are now resolved from saved preferences, falling back to the
  `⌃⌘,` / `⌃⌘.` / `⌃⌘/` and `⌃⌥→` / `⌃⌥←` defaults.

## 2.0.0

A ground-up rewrite of the classic **CatchMouse** (v1.2, 2011) for modern macOS.

### Added
- **Apple-Silicon-native** build. The binary is compiled for `arm64` (and
  ships as a universal `arm64 + x86_64` binary when possible) — no Rosetta.
- Rewritten from scratch in **Swift + AppKit + Carbon**; the original shipped
  only a 32/64-bit Intel (`i386` + `x86_64`) binary with no source.
- Programmatic menu-bar agent — no nibs, no storyboards.
- `⌃⌘,` / `⌃⌘.` / `⌃⌘/` jump to the left / centre / right display; `⌃⌥→` / `⌃⌥←`
  cycle between them.
- Scriptable CLI verbs: `--list`, `--move <n>`, `--move-next`, `--move-prev`.
- Live handling of displays being connected and disconnected.
- `build_app.sh` builds the `.app` with only the Command Line Tools installed.

### Changed
- Cursor movement uses `CGWarpMouseCursorPosition`, which requires **no
  Accessibility permission**.
- Minimum macOS raised from 10.5 to 11.0 (the Apple Silicon baseline).
