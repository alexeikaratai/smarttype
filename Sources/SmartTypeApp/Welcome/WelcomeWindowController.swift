import AppKit
import OSLog
import SwiftUI

/// The welcome window, shown until the person closes it: on the first launch, and again after
/// the relaunch Grant Access… makes, since quitting closes no window (`FirstLaunch`). Built when
/// shown and freed when closed, as Settings is.
final class WelcomeWindowController: NSObject {
    private(set) var window: NSWindow?
    private(set) var accessibility: AccessibilityViewModel?
    private(set) var layouts: LayoutSettingsModel?
    private(set) var translation: TranslationSettingsModel?

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
        window?.close()
    }

    private func makeWindow() -> NSWindow {
        let accessibility = AccessibilityViewModel(permission: permission)
        self.accessibility = accessibility
        let layouts = makeLayouts()
        self.layouts = layouts
        let translation = makeTranslation()
        self.translation = translation
        let content = WelcomeView(
            accessibility: accessibility, layouts: layouts, translation: translation, shortcuts: hotKeys.shortcuts,
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
    /// Back from System Settings: access may have been allowed, or a layout added.
    func windowDidBecomeKey(_ notification: Notification) {
        accessibility?.refresh()
        layouts?.refresh()
    }

    /// Closed in any way, it is done with: the next launch shows nothing.
    func windowWillClose(_ notification: Notification) {
        firstLaunch.isDone = true
        Log.general.notice("Welcome: closed for good")
        window = nil
        accessibility = nil
        layouts = nil
        translation = nil
    }
}
