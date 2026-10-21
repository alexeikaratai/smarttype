import AppKit

@testable import SmartTypeApp
@testable import SmartTypeCore
@testable import SmartTypeEngines

// The `forTest` builders: an action, the panel, Settings or the welcome window put together with
// recorders for everything that leaves the process.

extension WelcomeWindowController {
    /// Recorders for everything that leaves the process, and nothing put on the screen.
    static func forTest(
        _ test: String,
        macOS: PermissionRecorder? = nil,
        hotKeys: HotKeyBindings? = nil,
        firstLaunch: FirstLaunch? = nil,
        enabled: @escaping () -> [InputSourceLayout] = { [] },
        present: @escaping (NSWindow) -> Void = { _ in },
        file: String = #fileID
    ) -> WelcomeWindowController {
        WelcomeWindowController(
            hotKeys: hotKeys ?? HotKeyBindings(registrar: RecordingRegistrar(), store: .forTest(test, file: file)),
            permission: (macOS ?? PermissionRecorder(test: test, file: file)).permission(),
            firstLaunch: firstLaunch ?? .forTest(test, isDone: false, file: file),
            makeTranslation: { .forTest(test, file: file) },
            makeLayouts: { .forTest(test, enabled: enabled, file: file) },
            present: present)
    }
}

extension SettingsWindowController {
    /// Recorders for everything that leaves the process, and a `present` that brings nothing
    /// forward: a test must not put a window on the screen.
    static func forTest(
        _ test: String,
        macOS: PermissionRecorder? = nil,
        hotKeys: HotKeyBindings? = nil,
        loginItem: LoginItemRecorder = LoginItemRecorder(),
        enabled: @escaping () -> [InputSourceLayout] = { [] },
        present: @escaping (NSWindow) -> Void = { _ in },
        file: String = #fileID
    ) -> SettingsWindowController {
        SettingsWindowController(
            hotKeys: hotKeys ?? HotKeyBindings(registrar: RecordingRegistrar(), store: .forTest(test, file: file)),
            permission: (macOS ?? PermissionRecorder(test: test, file: file)).permission(),
            loginItem: loginItem,
            makeTranslation: { .forTest(test, file: file) },
            makeLayouts: { .forTest(test, enabled: enabled, file: file) },
            openURL: { _ in }, openLoginItems: {}, present: present)
    }
}

extension PanelController {
    /// Puts nothing on the screen and watches no clicks.
    static func forTest() -> PanelController {
        PanelController(present: { _ in }, pointer: { .zero }, visibleFrame: { _ in .zero }, watchClicks: { _ in {} })
    }
}

extension LayoutFixAction {
    /// The built-in layouts unless told others, the letter rules, and recorders for the rest.
    static func forTest(
        _ clipboard: ClipboardTransaction, _ macOS: PermissionRecorder, _ outcome: ActionOutcome = ActionOutcome(),
        layouts: [KeyboardLayout] = BuiltInLayouts().layouts, panel: PanelController = .forTest(),
        accessibilitySelection: String? = nil, smartTypeIsFrontmost: Bool = false, agrees: Bool = false
    ) -> LayoutFixAction {
        LayoutFixAction(
            makeCorrector: {
                LayoutCorrector(layouts: layouts, detector: LanguageDetector(scorers: [PhonotacticScorer()]))
            },
            clipboard: clipboard, permission: macOS.permission(), panel: panel,
            readSelection: { accessibilitySelection },
            selectLayout: { layoutID in
                outcome.onSwitch()
                outcome.layouts.append(layoutID)
                return true
            },
            isSmartTypeFrontmost: { smartTypeIsFrontmost }, beep: { outcome.beeps += 1 },
            explain: { problem in
                outcome.explained.append(problem)
                return agrees
            })
    }
}

extension TranslateAction {
    /// A fake engine that answers "en: …", English as the person's only language, and recorders
    /// for the rest.
    static func forTest(
        _ clipboard: ClipboardTransaction, _ macOS: PermissionRecorder, _ outcome: ActionOutcome = ActionOutcome(),
        panel: PanelController = .forTest(), isAvailable: Bool = true, accessibilitySelection: String? = nil,
        smartTypeIsFrontmost: Bool = false, agrees: Bool = false, test: String = #function, file: String = #fileID
    ) -> TranslateAction {
        TranslateAction(
            makeCard: { text in
                TranslationViewModel(
                    original: text, translator: FallbackTranslator(engines: [FakeTranslationEngine()]),
                    choices: .forTest(test, systemLanguages: [Locale.Language(identifier: "en")], file: file),
                    copy: { _ in }, openURL: { _ in })
            },
            clipboard: clipboard, permission: macOS.permission(), panel: panel,
            readSelection: { accessibilitySelection }, isAvailable: { isAvailable },
            isSmartTypeFrontmost: { smartTypeIsFrontmost }, beep: { outcome.beeps += 1 },
            explain: { problem in
                outcome.explained.append(problem)
                return agrees
            })
    }
}

extension StatusMenu {
    /// A menu filled with the default shortcuts, two layouts and version 1.2.3, and recorders.
    static func forTest(
        shortcuts: [AppCommand: KeyCombo] = Dictionary(
            uniqueKeysWithValues: AppCommand.allCases.map { ($0, $0.defaultHotKey) }),
        refused: Set<AppCommand> = [],
        needsAccess: Bool = false,
        layoutNames: [String] = ["U.S.", "Russian – PC"],
        perform: @escaping (AppCommand) -> Void = { _ in },
        isAvailable: @escaping (AppCommand) -> Bool = { _ in true },
        grantAccess: @escaping () -> Void = {},
        openSettings: @escaping () -> Void = {},
        openAbout: @escaping () -> Void = {},
        quit: @escaping () -> Void = {}
    ) -> NSMenu {
        let menu = NSMenu()
        StatusMenu.fill(
            menu,
            with: StatusMenu.Contents(
                version: "1.2.3", layoutNames: layoutNames, shortcuts: shortcuts, refusedHotKeys: refused,
                needsAccess: needsAccess),
            actions: StatusMenu.Actions(
                perform: perform, grantAccess: grantAccess, openSettings: openSettings, openAbout: openAbout, quit: quit
            ),
            isAvailable: isAvailable)
        return menu
    }
}
