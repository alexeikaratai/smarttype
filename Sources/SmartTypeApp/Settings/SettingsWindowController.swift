import AppKit
import OSLog
import SwiftUI

/// Owns the Settings window: AppKit for the window, SwiftUI for everything in it. The window is
/// built when opened and freed when closed, so nothing of it outlives the window.
final class SettingsWindowController: NSObject {
    private(set) var window: NSWindow?
    private(set) var accessibility: AccessibilityViewModel?
    private(set) var shortcuts: ShortcutsViewModel?

    private let hotKeys: HotKeyBindings
    private let permission: AccessibilityPermission
    private let info: AppInfo
    private let openURL: (URL) -> Void
    private let present: (NSWindow) -> Void

    init(
        hotKeys: HotKeyBindings,
        permission: AccessibilityPermission,
        info: AppInfo = AppInfo(),
        openURL: @escaping (URL) -> Void = { NSWorkspace.shared.open($0) },
        present: @escaping (NSWindow) -> Void = { SettingsWindowController.bringToFront($0) }
    ) {
        self.hotKeys = hotKeys
        self.permission = permission
        self.info = info
        self.openURL = openURL
        self.present = present
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
        let accessibility = AccessibilityViewModel(permission: permission)
        self.accessibility = accessibility
        let shortcuts = ShortcutsViewModel(bindings: hotKeys)
        self.shortcuts = shortcuts
        let content = SettingsView(
            accessibility: accessibility, translation: TranslationSettingsModel(), shortcuts: shortcuts, info: info,
            openURL: openURL)
        let window = SettingsWindow(
            contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: true)
        window.title = String(localized: "SmartType Settings", comment: "Settings window title, read out by VoiceOver")
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.contentView = Self.surface(for: NSHostingView(rootView: content), in: window)
        // Laid out first: only then does the size include the title bar the content sits below.
        window.layoutIfNeeded()
        window.setContentSize(window.contentView?.fittingSize ?? .zero)
        window.center()
        window.delegate = self
        return window
    }

    /// Liquid Glass from macOS 26, the whole window: clear itself, with the glass under the
    /// content and rounded as the window is (16pt on macOS 27, measured; the window's corner
    /// mask clips the glass either way, clear or not). Glass follows light and dark, where
    /// SmartDock's HUD material stayed dark and read as white text on grey (seen live). Before
    /// macOS 26, the standard background.
    private static func surface(for content: NSView, in window: NSWindow) -> NSView {
        guard #available(macOS 26, *) else { return content }
        window.isOpaque = false
        window.backgroundColor = .clear
        let glass = NSGlassEffectView()
        glass.cornerRadius = 16
        glass.contentView = content
        return glass
    }
}

// MARK: - NSWindowDelegate

extension SettingsWindowController: NSWindowDelegate {
    /// Back from System Settings: the person may have just switched SmartType on.
    func windowDidBecomeKey(_ notification: Notification) {
        accessibility?.refresh()
    }

    /// A recording under way gives the hotkeys back before the window goes.
    func windowWillClose(_ notification: Notification) {
        shortcuts?.stopRecording()
        window = nil
        accessibility = nil
        shortcuts = nil
    }
}
