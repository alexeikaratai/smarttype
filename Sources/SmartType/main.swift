import AppKit
import SmartTypeApp

// `NSApplication.delegate` is weak; a top-level constant lives as long as the process.
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
