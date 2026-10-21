import AppKit
import OSLog
import ServiceManagement
import SwiftUI

/// Owns the Settings window: AppKit for the window, SwiftUI for everything in it. The window is
/// built when opened and freed when closed, so nothing of it outlives the window.
final class SettingsWindowController: NSObject {
    private(set) var window: NSWindow?
    private(set) var accessibility: AccessibilityViewModel?
    private(set) var openAtLogin: OpenAtLoginViewModel?
    private(set) var shortcuts: ShortcutsViewModel?
    private(set) var translation: TranslationSettingsModel?
    private(set) var layouts: LayoutSettingsModel?
    private(set) var navigation: SettingsNavigation?

    private let hotKeys: HotKeyBindings
    private let permission: AccessibilityPermission
    private let loginItem: any LoginItemRegistering
    private let makeTranslation: () -> TranslationSettingsModel
    private let makeLayouts: () -> LayoutSettingsModel
    private let info: AppInfo
    private let openURL: (URL) -> Void
    private let openLoginItems: () -> Void
    private let present: (NSWindow) -> Void

    init(
        hotKeys: HotKeyBindings,
        permission: AccessibilityPermission,
        loginItem: any LoginItemRegistering,
        makeTranslation: @escaping () -> TranslationSettingsModel = { TranslationSettingsModel() },
        makeLayouts: @escaping () -> LayoutSettingsModel = { LayoutSettingsModel() },
        info: AppInfo = AppInfo(),
        openURL: @escaping (URL) -> Void = { NSWorkspace.shared.open($0) },
        openLoginItems: @escaping () -> Void = { SMAppService.openSystemSettingsLoginItems() },
        present: @escaping (NSWindow) -> Void = { SettingsWindowController.bringToFront($0) }
    ) {
        self.hotKeys = hotKeys
        self.permission = permission
        self.loginItem = loginItem
        self.makeTranslation = makeTranslation
        self.makeLayouts = makeLayouts
        self.info = info
        self.openURL = openURL
        self.openLoginItems = openLoginItems
        self.present = present
        super.init()
    }

    /// An agent app is not frontmost when its menu is used, so the window has to ask.
    static func bringToFront(_ window: NSWindow) {
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    /// On `tab` when given; otherwise on the tab it shows, General when it opens.
    func show(tab: SettingsTab? = nil) {
        let window = window ?? makeWindow()
        self.window = window
        if let tab {
            navigation?.tab = tab
        }
        present(window)
        Log.general.notice("Settings: shown")
    }

    // MARK: - Private

    private func makeWindow() -> NSWindow {
        let accessibility = AccessibilityViewModel(permission: permission)
        self.accessibility = accessibility
        let openAtLogin = OpenAtLoginViewModel(loginItem: loginItem, openLoginItems: openLoginItems)
        self.openAtLogin = openAtLogin
        let shortcuts = ShortcutsViewModel(bindings: hotKeys)
        self.shortcuts = shortcuts
        let translation = makeTranslation()
        self.translation = translation
        let layouts = makeLayouts()
        self.layouts = layouts
        let navigation = SettingsNavigation()
        self.navigation = navigation
        let content = SettingsView(
            accessibility: accessibility, openAtLogin: openAtLogin, translation: translation, layouts: layouts,
            shortcuts: shortcuts, navigation: navigation, info: info, openURL: openURL)
        let window = SettingsWindow.make(
            title: String(localized: "SmartType Settings", comment: "Settings window title, read out by VoiceOver"),
            content: NSHostingView(rootView: content))
        window.delegate = self
        return window
    }
}

// MARK: - NSWindowDelegate

extension SettingsWindowController: NSWindowDelegate {
    /// Back from System Settings: the person may have just switched SmartType on, in the
    /// Accessibility list or in Login Items, or added a layout. Or from the welcome window,
    /// with the languages changed there.
    func windowDidBecomeKey(_ notification: Notification) {
        accessibility?.refresh()
        openAtLogin?.refresh()
        layouts?.refresh()
        translation?.refresh()
    }

    /// Gone to another app in the middle of a recording: the hotkeys work there again.
    func windowDidResignKey(_ notification: Notification) {
        shortcuts?.stopRecording()
    }

    /// A recording under way gives the hotkeys back before the window goes.
    func windowWillClose(_ notification: Notification) {
        shortcuts?.stopRecording()
        window = nil
        accessibility = nil
        openAtLogin = nil
        shortcuts = nil
        translation = nil
        layouts = nil
        navigation = nil
    }
}
