import AppKit
import OSLog
import SmartTypeCore

/// Builds the object graph once. The only place that knows the concrete types.
final class AppComposition {
    private let hotKeys: HotKeyCenter
    private let statusBar: StatusBarController
    private let permission: AccessibilityPermission
    private let presentSettings: (NSWindow) -> Void
    private(set) var refusedHotKeys: Set<AppCommand> = []
    /// Built on first use, so a launch that never opens Settings never builds it.
    private lazy var settings = SettingsWindowController(
        refusedHotKeys: refusedHotKeys, permission: permission, present: presentSettings)
    /// Built on first use too: the dictionary and the layout tables load with the first ⌃⌥L.
    private lazy var layoutFix = LayoutFixAction(
        corrector: LayoutCorrector(
            layouts: BuiltInLayouts().layouts,
            detector: LanguageDetector(scorers: [PhonotacticScorer(), SpellCheckScorer()])),
        permission: permission)
    /// Built on first use too: the panel, and the list of languages, wait for the first ⌃⌥T.
    private lazy var translation = TranslateAction(permission: permission)

    init(
        hotKeyRegistrar: any HotKeyRegistering = CarbonHotKeyRegistrar(),
        statusBar: NSStatusBar = .system,
        permission: AccessibilityPermission = AccessibilityPermission(),
        presentSettings: @escaping (NSWindow) -> Void = { SettingsWindowController.bringToFront($0) }
    ) {
        hotKeys = HotKeyCenter(registrar: hotKeyRegistrar)
        self.statusBar = StatusBarController(statusBar: statusBar, permission: permission)
        self.permission = permission
        self.presentSettings = presentSettings
    }

    func start() {
        for command in AppCommand.allCases {
            let isRegistered = hotKeys.register(command.defaultHotKey) { [weak self] in
                self?.perform(command)
            }
            if !isRegistered {
                refusedHotKeys.insert(command)
            }
        }
        statusBar.show(
            refusedHotKeys: refusedHotKeys,
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

    /// The one entry point for every command, whichever door it came through.
    func perform(_ command: AppCommand) {
        Log.general.notice("Command: \(String(describing: command), privacy: .public)")
        switch command {
        case .fixLayout:
            Task { [weak self] in await self?.layoutFix.fixSelection() }
        case .translate:
            Task { [weak self] in await self?.translation.translateSelection() }
        }
    }

    /// Takes the status item out of the menu bar; used when a test is done with it.
    func stop() {
        hotKeys.unregisterAll()
        statusBar.remove()
    }
}
