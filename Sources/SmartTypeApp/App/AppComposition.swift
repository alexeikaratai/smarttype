import AppKit
import Carbon.HIToolbox
import OSLog
import ServiceManagement
import SmartTypeCore

/// The composition root: builds the object graph once and wires the doors to the actions.
final class AppComposition {
    private let hotKeys: HotKeyBindings
    private let statusBar: StatusBarController
    private let permission: AccessibilityPermission
    private let loginItem: any LoginItemRegistering
    private let firstLaunch: FirstLaunch
    private let presentSettings: (NSWindow) -> Void
    private let offerServices: (NSObject) -> Void
    /// The languages and the layouts in Settings and the welcome window, built with them.
    private let makeTranslation: () -> TranslationSettingsModel
    private let makeLayouts: () -> LayoutSettingsModel
    var refusedHotKeys: Set<AppCommand> { hotKeys.refused }
    /// One for both commands, so neither borrows the clipboard while the other has it.
    private let clipboard = ClipboardTransaction()
    /// One for both commands too: Fix Layout closes it, or its ⌘C would go to the panel. Its
    /// window is built only for the first translation.
    private let panel = PanelController()
    /// Built on first use, so a launch that never opens Settings never builds it.
    private lazy var settings = SettingsWindowController(
        hotKeys: hotKeys, permission: permission, loginItem: loginItem, makeTranslation: makeTranslation,
        makeLayouts: makeLayouts, present: presentSettings)
    /// Built only for a launch that shows it.
    private lazy var welcome = WelcomeWindowController(
        hotKeys: hotKeys, permission: permission, firstLaunch: firstLaunch, makeTranslation: makeTranslation,
        makeLayouts: makeLayouts, present: presentSettings)
    /// Built on first use too. The layouts are read from macOS on every fix, less those switched
    /// off in Settings, so a layout added in macOS a moment ago is already one of them.
    private lazy var layoutFix = LayoutFixAction(
        makeCorrector: {
            LayoutCorrector(
                layouts: LayoutChoices().switchedOn().map(\.layout),
                detector: LanguageDetector(scorers: [PhonotacticScorer(), SpellCheckScorer()]))
        },
        clipboard: clipboard, permission: permission, panel: panel)
    /// Built on first use too.
    private lazy var translation = TranslateAction(clipboard: clipboard, permission: permission, panel: panel)

    init(
        hotKeyRegistrar: any HotKeyRegistering = CarbonHotKeyRegistrar(),
        hotKeyStore: HotKeyStore = HotKeyStore(),
        statusBar: NSStatusBar = .system,
        permission: AccessibilityPermission = AccessibilityPermission(relaunch: { AppRelauncher.relaunch() }),
        loginItem: any LoginItemRegistering = SMAppService.mainApp,
        firstLaunch: FirstLaunch = FirstLaunch(),
        makeTranslation: @escaping () -> TranslationSettingsModel = { TranslationSettingsModel() },
        makeLayouts: @escaping () -> LayoutSettingsModel = { LayoutSettingsModel() },
        presentSettings: @escaping (NSWindow) -> Void = { SettingsWindowController.bringToFront($0) },
        offerServices: @escaping (NSObject) -> Void = { AppComposition.offerToServices($0) }
    ) {
        hotKeys = HotKeyBindings(registrar: hotKeyRegistrar, store: hotKeyStore)
        self.statusBar = StatusBarController(statusBar: statusBar, permission: permission)
        self.permission = permission
        self.loginItem = loginItem
        self.firstLaunch = firstLaunch
        self.makeTranslation = makeTranslation
        self.makeLayouts = makeLayouts
        self.presentSettings = presentSettings
        self.offerServices = offerServices
    }

    func start() {
        hotKeys.perform = { [weak self] command in self?.perform(command) }
        hotKeys.apply()
        offerServices(
            TextServiceProvider(
                fixInPlace: { [weak self] in self?.layoutFix.fixInPlace($0) },
                translateText: { [weak self] text in
                    Task { [weak self] in await self?.translation.translateText(text) }
                }))
        statusBar.show(
            hotKeys: hotKeys,
            perform: { [weak self] command in self?.perform(command) },
            openSettings: { [weak self] in self?.settings.show() },
            openAbout: { [weak self] in self?.settings.show(tab: .about) }
        )
        // The relaunch that ends a reset: only this new process puts SmartType back in the list.
        // As in SmartDock, a window opens too, to show the status next to System Settings: the
        // welcome window until the person has closed it, Settings after.
        let isAfterAReset = permission.asksAfterNextLaunch
        permission.asksAfterNextLaunch = false
        if !firstLaunch.isDone {
            welcome.show()
        } else if isAfterAReset {
            settings.show()
        }
        if isAfterAReset {
            Log.permissions.notice("Accessibility: asking again after a reset")
            permission.requestAccess()
        }
    }

    /// The one entry point for the hotkeys and the menu, which act on the selection. Services
    /// bring their text with them, so the provider calls the actions' Services doors instead.
    /// The log names the app in front and whether a password field holds Secure Input, never
    /// any text.
    func perform(_ command: AppCommand) {
        let app = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "?"
        Log.general.notice(
            "Command: \(String(describing: command), privacy: .public) in \(app, privacy: .public), Secure Input \(IsSecureEventInputEnabled() ? "on" : "off", privacy: .public)"
        )
        switch command {
        case .fixLayout:
            Task { [weak self] in await self?.layoutFix.fixSelection() }
        case .translate:
            Task { [weak self] in await self?.translation.translateSelection() }
        }
    }

    /// Takes the status item out of the menu bar; used when a test is done with it.
    func stop() {
        hotKeys.pause()
        statusBar.remove()
    }

    // MARK: - Private

    /// AppKit keeps the provider, and macOS reads the app's Services again: a build run from
    /// anywhere shows them once LaunchServices knows the bundle, not only from /Applications
    /// (measured with `lsregister` and `pbs -dump`).
    private static func offerToServices(_ provider: NSObject) {
        NSApp.servicesProvider = provider
        NSUpdateDynamicServices()
    }
}
