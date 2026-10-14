import AppKit
import Carbon.HIToolbox
import OSLog
import ServiceManagement
import SmartTypeCore

/// Builds the object graph once. The only place that knows the concrete types.
final class AppComposition {
    private let hotKeys: HotKeyBindings
    private let statusBar: StatusBarController
    private let permission: AccessibilityPermission
    private let loginItem: any LoginItemRegistering
    private let presentSettings: (NSWindow) -> Void
    private let offerServices: (NSObject) -> Void
    var refusedHotKeys: Set<AppCommand> { hotKeys.refused }
    /// One for both commands, so neither borrows the clipboard while the other has it.
    private let clipboard = ClipboardTransaction()
    /// Built on first use, so a launch that never opens Settings never builds it.
    private lazy var settings = SettingsWindowController(
        hotKeys: hotKeys, permission: permission, loginItem: loginItem, present: presentSettings)
    /// Built on first use too: the dictionary and the layout tables load with the first fix.
    private lazy var layoutFix = LayoutFixAction(
        corrector: LayoutCorrector(
            layouts: BuiltInLayouts().layouts,
            detector: LanguageDetector(scorers: [PhonotacticScorer(), SpellCheckScorer()])),
        clipboard: clipboard, permission: permission)
    /// Built on first use too: the panel waits for the first translation.
    private lazy var translation = TranslateAction(clipboard: clipboard, permission: permission)

    init(
        hotKeyRegistrar: any HotKeyRegistering = CarbonHotKeyRegistrar(),
        hotKeyStore: HotKeyStore = HotKeyStore(),
        statusBar: NSStatusBar = .system,
        permission: AccessibilityPermission = AccessibilityPermission(relaunch: { AppRelauncher.relaunch() }),
        loginItem: any LoginItemRegistering = SMAppService.mainApp,
        presentSettings: @escaping (NSWindow) -> Void = { SettingsWindowController.bringToFront($0) },
        offerServices: @escaping (NSObject) -> Void = { AppComposition.offerToServices($0) }
    ) {
        hotKeys = HotKeyBindings(registrar: hotKeyRegistrar, store: hotKeyStore)
        self.statusBar = StatusBarController(statusBar: statusBar, permission: permission)
        self.permission = permission
        self.loginItem = loginItem
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
            openSettings: { [weak self] in self?.settings.show() }
        )
        // The relaunch that ends a reset: only this new process puts SmartType back in the list.
        // As in SmartDock, Settings opens too, to show the status next to System Settings.
        if permission.asksAfterNextLaunch {
            permission.asksAfterNextLaunch = false
            Log.permissions.notice("Accessibility: asking again after a reset")
            settings.show()
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
