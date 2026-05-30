import AppKit

/// Wires together the display manager, global hotkeys, the menu-bar UI and the
/// Preferences window, and keeps the hotkeys in sync as displays change or the
/// user edits their shortcuts.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let displays = DisplayManager()
    private let hotKeys = HotKeyCenter()
    private let store = HotKeyStore.shared
    private let openPreferencesOnLaunch: Bool
    private var menu: StatusMenuController!
    private lazy var preferences = PreferencesWindowController(displays: displays, store: store) { [weak self] in
        self?.reload()
    }

    init(openPreferencesOnLaunch: Bool = false) {
        self.openPreferencesOnLaunch = openPreferencesOnLaunch
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        menu = StatusMenuController(displays: displays, store: store) { [weak self] action in
            self?.perform(action)
        }
        reload()
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        if openPreferencesOnLaunch { preferences.show() }
    }

    @objc private func screensChanged() { reload() }

    /// Re-register hotkeys and rebuild the menu to match the current displays
    /// and the user's stored shortcuts.
    private func reload() {
        registerHotKeys()
        menu.rebuild()
    }

    private func perform(_ action: MenuAction) {
        switch action {
        case .moveTo(let index):
            let ids = displays.orderedDisplays()
            if ids.indices.contains(index) { displays.moveCursor(to: ids[index]) }
        case .next:
            displays.moveToAdjacentDisplay(forward: true)
        case .previous:
            displays.moveToAdjacentDisplay(forward: false)
        case .openPreferences:
            preferences.show()
        case .identifyDisplays:
            DisplayIdentifier.flash(displays: displays)
        }
    }

    private func registerHotKeys() {
        hotKeys.unregisterAll()

        // Per-display jump keys (user binding, or positional default).
        for (index, id) in displays.orderedDisplays().enumerated() {
            let key = displays.stableKey(for: id)
            guard let combo = Shortcuts.jumpCombo(index: index, displayKey: key, store: store) else { continue }
            hotKeys.register(keyCode: combo.keyCode, modifiers: combo.carbonModifiers) { [weak self] in
                guard let self, let target = self.displays.display(forStableKey: key) else { return }
                self.displays.moveCursor(to: target)
            }
        }

        // Cycle keys.
        let next = Shortcuts.nextCombo(store)
        hotKeys.register(keyCode: next.keyCode, modifiers: next.carbonModifiers) { [weak self] in
            self?.displays.moveToAdjacentDisplay(forward: true)
        }
        let prev = Shortcuts.prevCombo(store)
        hotKeys.register(keyCode: prev.keyCode, modifiers: prev.carbonModifiers) { [weak self] in
            self?.displays.moveToAdjacentDisplay(forward: false)
        }
    }
}
