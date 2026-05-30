import AppKit
import Carbon.HIToolbox

/// Translate AppKit modifier flags into Carbon modifier flags.
func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
    var m = 0
    if flags.contains(.command) { m |= cmdKey }
    if flags.contains(.option)  { m |= optionKey }
    if flags.contains(.control) { m |= controlKey }
    if flags.contains(.shift)   { m |= shiftKey }
    return m
}

/// A click-to-record control for a single global shortcut. Click it, press the
/// combination you want, and it reports the captured `KeyCombo`. Press ⎋ to
/// cancel or ⌫ to clear the binding.
final class HotKeyRecorderView: NSView {
    var combo: KeyCombo? { didSet { needsDisplay = true } }
    /// Called with the new combo, or `nil` when the user clears it.
    var onChange: ((KeyCombo?) -> Void)?

    private var recording = false { didSet { needsDisplay = true } }

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 150, height: 24) }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
        (recording ? NSColor.controlAccentColor.withAlphaComponent(0.15)
                   : NSColor.controlBackgroundColor).setFill()
        path.fill()
        (recording ? NSColor.controlAccentColor : NSColor.separatorColor).setStroke()
        path.lineWidth = recording ? 2 : 1
        path.stroke()

        let text: String
        let color: NSColor
        if recording {
            text = "Press keys… (⎋ cancel)"; color = .secondaryLabelColor
        } else if let combo {
            text = combo.displayString; color = .labelColor
        } else {
            text = "Click to record"; color = .secondaryLabelColor
        }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12), .foregroundColor: color,
        ]
        let ns = text as NSString
        let size = ns.size(withAttributes: attrs)
        ns.draw(at: NSPoint(x: (bounds.width - size.width) / 2,
                            y: (bounds.height - size.height) / 2), withAttributes: attrs)
    }

    override func mouseDown(with event: NSEvent) {
        guard !recording else { return }
        window?.makeFirstResponder(self)
        recording = true
    }

    override func becomeFirstResponder() -> Bool { needsDisplay = true; return true }
    override func resignFirstResponder() -> Bool { recording = false; return true }

    override func keyDown(with event: NSEvent) {
        if recording { handle(event) } else { super.keyDown(with: event) }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard recording else { return super.performKeyEquivalent(with: event) }
        handle(event)
        return true
    }

    private func handle(_ event: NSEvent) {
        let code = Int(event.keyCode)
        if code == kVK_Escape { finish(); return }
        if code == kVK_Delete || code == kVK_ForwardDelete {
            combo = nil; onChange?(nil); finish(); return
        }
        let mods = carbonModifiers(from: event.modifierFlags)
        guard (mods & (cmdKey | controlKey | optionKey)) != 0 else { NSSound.beep(); return }
        let captured = KeyCombo(keyCode: code, carbonModifiers: mods)
        combo = captured
        onChange?(captured)
        finish()
    }

    private func finish() {
        recording = false
        window?.makeFirstResponder(nil)
    }
}
