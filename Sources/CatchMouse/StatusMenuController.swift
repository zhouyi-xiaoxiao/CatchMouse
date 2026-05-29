import AppKit

/// An action emitted by the menu, handled by `AppDelegate`.
enum MenuAction {
    case moveTo(Int)   // display index (0-based, left → right)
    case next
    case previous
}

/// Owns the menu-bar status item and rebuilds its menu to reflect the displays
/// currently attached to the machine.
final class StatusMenuController: NSObject {
    private let statusItem: NSStatusItem
    private let displays: DisplayManager
    private let onAction: (MenuAction) -> Void

    init(displays: DisplayManager, onAction: @escaping (MenuAction) -> Void) {
        self.displays = displays
        self.onAction = onAction
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "cursorarrow.rays",
                                   accessibilityDescription: "CatchMouse") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "⤢"
            }
        }
    }

    func rebuild() {
        let menu = NSMenu()
        menu.addItem(disabled("CatchMouse"))
        menu.addItem(.separator())

        let ids = displays.orderedDisplays()
        if ids.isEmpty {
            menu.addItem(disabled("No displays detected"))
        } else {
            for (index, id) in ids.enumerated() {
                let bounds = CGDisplayBounds(id)
                let isMain = (id == CGMainDisplayID()) ? " · main" : ""
                let shortcut = index < 9 ? "   ⌃⌥\(index + 1)" : ""
                let item = NSMenuItem(
                    title: "Display \(index + 1) — \(Int(bounds.width))×\(Int(bounds.height))\(isMain)\(shortcut)",
                    action: #selector(moveToDisplay(_:)), keyEquivalent: "")
                item.target = self
                item.tag = index
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        menu.addItem(action("Move to Next Display   ⌃⌥→", #selector(moveNext)))
        menu.addItem(action("Move to Previous Display   ⌃⌥←", #selector(movePrev)))

        menu.addItem(.separator())
        menu.addItem(action("About CatchMouse", #selector(showAbout)))
        let quit = action("Quit CatchMouse", #selector(quit))
        quit.keyEquivalent = "q"
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - Item builders

    private func action(_ title: String, _ selector: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        item.target = self
        return item
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    // MARK: - Actions

    @objc private func moveToDisplay(_ sender: NSMenuItem) { onAction(.moveTo(sender.tag)) }
    @objc private func moveNext() { onAction(.next) }
    @objc private func movePrev() { onAction(.previous) }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "CatchMouse",
            .applicationVersion: appVersion,
            .init(rawValue: "Copyright"): "MIT licensed · a modern reimplementation of the classic CatchMouse"
        ])
    }
}
