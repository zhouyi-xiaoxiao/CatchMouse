import AppKit

// Argument handling:
//   --preferences / --prefs  → launch the menu-bar agent and open Preferences
//   any other argument(s)    → run a scriptable CLI verb and exit
//   no arguments             → launch the menu-bar agent
let extraArgs = Array(CommandLine.arguments.dropFirst())
let openPreferences = extraArgs.contains("--preferences") || extraArgs.contains("--prefs")
let cliArgs = extraArgs.filter { $0 != "--preferences" && $0 != "--prefs" }

if !openPreferences, !cliArgs.isEmpty {
    exit(runCLI(arguments: cliArgs))
}

let app = NSApplication.shared
let delegate = AppDelegate(openPreferencesOnLaunch: openPreferences)
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menu-bar agent: no Dock icon, no main window
app.run()
