import AppKit

/// The Preferences window: one hotkey recorder per display plus next/previous
/// cycle recorders, an "Identify Displays" helper and a reset button. Rebuilds
/// itself whenever displays are connected or disconnected.
final class PreferencesWindowController: NSObject, NSWindowDelegate {
    private let displays: DisplayManager
    private let store: HotKeyStore
    private let onChanged: () -> Void
    private var window: NSWindow?
    private var observer: NSObjectProtocol?

    init(displays: DisplayManager, store: HotKeyStore, onChanged: @escaping () -> Void) {
        self.displays = displays
        self.store = store
        self.onChanged = onChanged
        super.init()
    }

    func show() {
        if window == nil { buildWindow() }
        rebuild()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private func buildWindow() {
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 360),
                         styleMask: [.titled, .closable, .miniaturizable],
                         backing: .buffered, defer: false)
        w.title = "CatchMouse Preferences"
        w.isReleasedWhenClosed = false
        w.delegate = self
        w.center()
        window = w
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main) { [weak self] _ in self?.rebuild() }
    }

    // MARK: - Building rows

    private func sectionTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .boldSystemFont(ofSize: 13)
        return label
    }

    private func row(_ text: String, _ recorder: HotKeyRecorderView) -> NSStackView {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13)
        label.lineBreakMode = .byTruncatingTail
        label.widthAnchor.constraint(equalToConstant: 240).isActive = true
        let h = NSStackView(views: [label, recorder])
        h.orientation = .horizontal
        h.spacing = 12
        h.alignment = .centerY
        return h
    }

    private func recorder(_ combo: KeyCombo?, _ onChange: @escaping (KeyCombo?) -> Void) -> HotKeyRecorderView {
        let r = HotKeyRecorderView()
        r.combo = combo
        r.onChange = onChange
        r.translatesAutoresizingMaskIntoConstraints = false
        r.widthAnchor.constraint(equalToConstant: 160).isActive = true
        r.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return r
    }

    private func rebuild() {
        guard let window else { return }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 22, bottom: 18, right: 22)
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(sectionTitle("Jump to display"))

        let ids = displays.orderedDisplays()
        if ids.isEmpty {
            stack.addArrangedSubview(NSTextField(labelWithString: "No displays detected."))
        }
        for (index, id) in ids.enumerated() {
            let key = displays.stableKey(for: id)
            let b = CGDisplayBounds(id)
            let main = (id == CGMainDisplayID()) ? " · main" : ""
            let r = recorder(Shortcuts.jumpCombo(index: index, displayKey: key, store: store)) { [weak self] combo in
                self?.store.setBinding(combo, forDisplay: key)
                self?.onChanged()
            }
            stack.addArrangedSubview(row("Display \(index + 1) — \(Int(b.width))×\(Int(b.height))\(main)", r))
        }

        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.widthAnchor.constraint(equalToConstant: 412).isActive = true
        stack.addArrangedSubview(sep)

        stack.addArrangedSubview(sectionTitle("Cycle displays"))
        let nextRec = recorder(Shortcuts.nextCombo(store)) { [weak self] c in self?.store.setNext(c); self?.onChanged() }
        stack.addArrangedSubview(row("Next display", nextRec))
        let prevRec = recorder(Shortcuts.prevCombo(store)) { [weak self] c in self?.store.setPrev(c); self?.onChanged() }
        stack.addArrangedSubview(row("Previous display", prevRec))

        let identify = NSButton(title: "Identify Displays", target: self, action: #selector(identify))
        let reset = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetDefaults))
        let buttons = NSStackView(views: [identify, reset])
        buttons.orientation = .horizontal
        buttons.spacing = 12
        stack.addArrangedSubview(buttons)

        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
        ])
        window.contentView = content
        window.layoutIfNeeded()
        let fitting = stack.fittingSize
        window.setContentSize(NSSize(width: max(460, fitting.width), height: max(260, fitting.height)))
    }

    @objc private func identify() { DisplayIdentifier.flash(displays: displays) }

    @objc private func resetDefaults() {
        store.resetAll()
        onChanged()
        rebuild()
    }

    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }
}

/// Briefly flashes a large number on each display so the user can tell which is
/// "Display 1", "Display 2", … (matching the left→right numbering elsewhere).
enum DisplayIdentifier {
    static func flash(displays: DisplayManager) {
        let ids = displays.orderedDisplays()
        var windows: [NSWindow] = []
        for (index, id) in ids.enumerated() {
            guard let screen = NSScreen.screens.first(where: {
                ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) == id
            }) else { continue }

            let w = NSWindow(contentRect: screen.frame, styleMask: .borderless,
                             backing: .buffered, defer: false)
            w.isOpaque = false
            w.backgroundColor = .clear
            w.level = .screenSaver
            w.ignoresMouseEvents = true
            w.collectionBehavior = [.canJoinAllSpaces, .stationary]

            let container = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
            let badge = NSView()
            badge.wantsLayer = true
            badge.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.55).cgColor
            badge.layer?.cornerRadius = 32
            badge.translatesAutoresizingMaskIntoConstraints = false

            let label = NSTextField(labelWithString: "\(index + 1)")
            label.font = .systemFont(ofSize: 180, weight: .bold)
            label.textColor = .white
            label.alignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false

            badge.addSubview(label)
            container.addSubview(badge)
            NSLayoutConstraint.activate([
                badge.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                badge.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                label.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
                badge.widthAnchor.constraint(equalTo: label.widthAnchor, constant: 90),
                badge.heightAnchor.constraint(equalTo: label.heightAnchor, constant: 50),
            ])
            w.contentView = container
            w.orderFrontRegardless()
            windows.append(w)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            for w in windows { w.orderOut(nil) }
        }
    }
}
