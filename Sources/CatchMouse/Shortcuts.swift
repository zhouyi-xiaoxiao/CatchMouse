import Carbon.HIToolbox

/// Single source of truth for the global shortcuts, shared by the hotkey
/// registration, the menu-bar labels and the CLI help text.
///
/// Displays are ordered left → right, so `jumpKeys[0]` is the left-most display,
/// `[1]` the centre, `[2]` the right.
enum Shortcuts {
    /// Carbon modifier mask for the per-display jump keys: Control + Command.
    static let jumpModifiers = controlKey | cmdKey

    /// (Carbon key code, human label) for the left / centre / right displays.
    /// `,` `.` `/` are three adjacent keys, mapping naturally to left/centre/right.
    static let jumpKeys: [(keyCode: Int, label: String)] = [
        (kVK_ANSI_Comma,  "⌃⌘,"),
        (kVK_ANSI_Period, "⌃⌘."),
        (kVK_ANSI_Slash,  "⌃⌘/"),
    ]

    /// Carbon modifier mask for the cycle keys: Control + Option.
    static let cycleModifiers = controlKey | optionKey
    static let nextLabel = "⌃⌥→"
    static let prevLabel = "⌃⌥←"
}
