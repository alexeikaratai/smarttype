import AppKit
import OSLog
import SwiftUI

/// Owns the Settings window: AppKit for the window, SwiftUI for everything in it. The window is
/// built when opened and freed when closed, so nothing of it outlives the window.
final class SettingsWindowController: NSObject {
    private(set) var window: NSWindow?
    private(set) var accessibility: AccessibilityViewModel?

    private let shortcuts: [Shortcut]
    private let permission: AccessibilityPermission
    private let info: AppInfo
    private let openURL: (URL) -> Void
    private let present: (NSWindow) -> Void
    private let relaunch: () -> Void

    init(
        refusedHotKeys: Set<AppCommand>,
        permission: AccessibilityPermission = AccessibilityPermission(),
        info: AppInfo = AppInfo(),
        openURL: @escaping (URL) -> Void = { NSWorkspace.shared.open($0) },
        present: @escaping (NSWindow) -> Void = { SettingsWindowController.bringToFront($0) },
        relaunch: @escaping () -> Void = { AppRelauncher.relaunch() }
    ) {
        shortcuts = Shortcut.all(refused: refusedHotKeys)
        self.permission = permission
        self.info = info
        self.openURL = openURL
        self.present = present
        self.relaunch = relaunch
        super.init()
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        present(window)
        Log.general.notice("Settings: shown")
    }

    /// An agent app is not frontmost when its menu is used, so the window has to ask.
    static func bringToFront(_ window: NSWindow) {
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - Private

    private func makeWindow() -> NSWindow {
        let accessibility = AccessibilityViewModel(permission: permission, relaunch: relaunch)
        self.accessibility = accessibility
        let content = SettingsView(accessibility: accessibility, shortcuts: shortcuts, info: info, openURL: openURL)
        let window = SettingsWindow(
            contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: true)
        window.title = String(localized: "SmartType Settings", comment: "Settings window title, read out by VoiceOver")
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        // The standard background, which follows light and dark. SmartDock's HUD glass stays
        // dark in light mode, and the window read as white text on grey.
        window.contentView = NSHostingView(rootView: content)
        // Laid out first: only then does the size include the title bar the content sits below.
        window.layoutIfNeeded()
        window.setContentSize(window.contentView?.fittingSize ?? .zero)
        window.center()
        window.delegate = self
        return window
    }
}

// MARK: - NSWindowDelegate

extension SettingsWindowController: NSWindowDelegate {
    /// Back from System Settings: the person may have just switched SmartType on.
    func windowDidBecomeKey(_ notification: Notification) {
        accessibility?.refresh()
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        accessibility = nil
    }
}
