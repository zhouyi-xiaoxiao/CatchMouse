import AppKit

// Scriptable / headless mode: any argument runs a CLI verb and exits without
// launching the menu-bar agent. Handy for testing and for binding to other tools.
if CommandLine.arguments.count > 1 {
    exit(runCLI(arguments: Array(CommandLine.arguments.dropFirst())))
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menu-bar agent: no Dock icon, no main window
app.run()
