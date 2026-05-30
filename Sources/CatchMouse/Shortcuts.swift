import Carbon.HIToolbox

/// Default shortcuts and the logic that resolves a display's effective combo
/// (user-chosen binding from the store, falling back to a positional default).
///
/// Displays are ordered left → right, so default index 0 is the left-most.
enum Shortcuts {
    /// Positional defaults for the left / centre / right displays:
    /// `⌃⌘,` `⌃⌘.` `⌃⌘/` (three adjacent keys, no system-shortcut clash —
    /// macOS Help is ⇧⌘/, not ⌃⌘/).
    static let defaultJump: [KeyCombo] = [
        KeyCombo(keyCode: kVK_ANSI_Comma,  carbonModifiers: controlKey | cmdKey),
        KeyCombo(keyCode: kVK_ANSI_Period, carbonModifiers: controlKey | cmdKey),
        KeyCombo(keyCode: kVK_ANSI_Slash,  carbonModifiers: controlKey | cmdKey),
    ]
    static let defaultNext = KeyCombo(keyCode: kVK_RightArrow, carbonModifiers: controlKey | optionKey)
    static let defaultPrev = KeyCombo(keyCode: kVK_LeftArrow,  carbonModifiers: controlKey | optionKey)

    /// Effective jump combo for the display at `index` (left→right): the stored
    /// per-display binding if any, otherwise the positional default (first three
    /// displays only). Returns `nil` if the display has no shortcut.
    static func jumpCombo(index: Int, displayKey: String, store: HotKeyStore) -> KeyCombo? {
        if let stored = store.binding(forDisplay: displayKey) { return stored }
        return index < defaultJump.count ? defaultJump[index] : nil
    }

    static func nextCombo(_ store: HotKeyStore) -> KeyCombo { store.nextBinding() ?? defaultNext }
    static func prevCombo(_ store: HotKeyStore) -> KeyCombo { store.prevBinding() ?? defaultPrev }
}
