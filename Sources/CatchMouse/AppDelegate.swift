import AppKit
import Carbon.HIToolbox

/// Wires together the display manager, global hotkeys and the menu-bar UI, and
/// keeps them in sync as displays are connected or disconnected.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let displays = DisplayManager()
    private let hotKeys = HotKeyCenter()
    private var menu: StatusMenuController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        menu = StatusMenuController(displays: displays) { [weak self] action in
            self?.perform(action)
        }
        reload()
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    @objc private func screensChanged() { reload() }

    /// Re-register hotkeys and rebuild the menu to match the current displays.
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
        }
    }

    private func registerHotKeys() {
        hotKeys.unregisterAll()
        let mods = controlKey | optionKey

        // ⌃⌥1 … ⌃⌥9  →  jump straight to display 1 … 9 (left → right).
        let numberKeys = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5,
                          kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9]
        let count = min(displays.orderedDisplays().count, numberKeys.count)
        for index in 0..<count {
            hotKeys.register(keyCode: numberKeys[index], modifiers: mods) { [weak self] in
                guard let self else { return }
                let ids = self.displays.orderedDisplays()
                if ids.indices.contains(index) { self.displays.moveCursor(to: ids[index]) }
            }
        }

        // ⌃⌥→ / ⌃⌥←  →  cycle to the next / previous display.
        hotKeys.register(keyCode: kVK_RightArrow, modifiers: mods) { [weak self] in
            self?.displays.moveToAdjacentDisplay(forward: true)
        }
        hotKeys.register(keyCode: kVK_LeftArrow, modifiers: mods) { [weak self] in
            self?.displays.moveToAdjacentDisplay(forward: false)
        }
    }
}
