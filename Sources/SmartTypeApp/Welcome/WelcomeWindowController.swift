import AppKit
import OSLog
import SwiftUI

/// The welcome window, shown until the person closes it (`FirstLaunch`): on the first launch,
/// and again after the relaunch Grant Access… makes. Built when shown and freed when closed, as
/// Settings is.
final class WelcomeWindowController: NSObject {
    private(set) var window: NSWindow?
    private(set) var accessibility: AccessibilityViewModel?
    private(set) var layouts: LayoutSettingsModel?
    private(set) var translation: TranslationSettingsModel?
    private(set) var shortcuts: ShortcutsViewModel?

    private let hotKeys: HotKeyBindings
    private let permission: AccessibilityPermission
    private let firstLaunch: FirstLaunch
    private let makeTranslation: () -> TranslationSettingsModel
    private let makeLayouts: () -> LayoutSettingsModel
    private let present: (NSWindow) -> Void

    init(
        hotKeys: HotKeyBindings,
        permission: AccessibilityPermission,
        firstLaunch: FirstLaunch,
        makeTranslation: @escaping () -> TranslationSettingsModel = { TranslationSettingsModel() },
        makeLayouts: @escaping () -> LayoutSettingsModel = { LayoutSettingsModel() },
        present: @escaping (NSWindow) -> Void
    ) {
        self.hotKeys = hotKeys
        self.permission = permission
        self.firstLaunch = firstLaunch
        self.makeTranslation = makeTranslation
        self.makeLayouts = makeLayouts
        self.present = present
        super.init()
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        present(window)
        Log.general.notice("Welcome: shown")
    }

    /// Done closes the window as its close button does.
    func done() {
        window?.performClose(nil)
    }

    private func makeWindow() -> NSWindow {
        let accessibility = AccessibilityViewModel(permission: permission)
        self.accessibility = accessibility
        let layouts = makeLayouts()
        self.layouts = layouts
        let translation = makeTranslation()
        self.translation = translation
        let shortcuts = ShortcutsViewModel(bindings: hotKeys)
        self.shortcuts = shortcuts
        let content = WelcomeView(
            accessibility: accessibility, layouts: layouts, translation: translation, shortcuts: shortcuts,
            height: WelcomeView.height(fitting: NSScreen.main?.visibleFrame.height),
            onDone: { [weak self] in self?.done() })
        let window = SettingsWindow.make(
            title: String(localized: "Welcome to SmartType", comment: "Welcome window: title"),
            content: NSHostingView(rootView: content))
        window.delegate = self
        return window
    }
}

// MARK: - NSWindowDelegate

extension WelcomeWindowController: NSWindowDelegate {
    /// Back from System Settings: access may have been allowed, or a layout added. Or from
    /// Settings, with a shortcut or the languages changed there.
    func windowDidBecomeKey(_ notification: Notification) {
        accessibility?.refresh()
        layouts?.refresh()
        translation?.refresh()
        shortcuts?.refresh()
    }

    /// The person closed it: the close button, Esc, ⌘W and Done all go through `performClose`.
    /// Quitting closes the window too but never asks (measured: `windowWillClose` alone), and
    /// in 0.3.0 the relaunch Grant Access… makes closed it for good that way (seen in the log).
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        firstLaunch.isDone = true
        Log.general.notice("Welcome: closed for good")
        return true
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        accessibility = nil
        layouts = nil
        translation = nil
        shortcuts = nil
    }
}
