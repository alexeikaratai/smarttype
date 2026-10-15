import AppKit

@testable import SmartTypeApp
@testable import SmartTypeCore
@testable import SmartTypeEngines

/// Waits for an event, never for a fixed time: checks `condition` until it holds, giving up
/// after `timeout`. Returns whether it held.
func waitUntil(timeout: Duration = .seconds(2), _ condition: () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        guard ContinuousClock.now < deadline else { return false }
        try? await Task.sleep(for: .milliseconds(5))
    }
    return true
}

extension UserDefaults {
    /// A defaults domain per test and per part, emptied first and never the app's own. Parts keep
    /// the fakes of one test from emptying each other's domain.
    static func forTest(_ test: String, part: String, file: String = #fileID) -> UserDefaults {
        let suite = "com.smarttype.tests.\(file).\(test).\(part)".replacingOccurrences(of: "/", with: ".")
        let defaults = UserDefaults(suiteName: suite) ?? UserDefaults()
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}

extension TranslationChoices {
    /// The macOS languages are fixed, not this Mac's, so a test reads the same everywhere.
    static func forTest(
        _ test: String,
        systemLanguages: [Locale.Language] = [
            Locale.Language(identifier: "en-US"), Locale.Language(identifier: "ru-PL"),
        ],
        file: String = #fileID
    ) -> TranslationChoices {
        TranslationChoices(defaults: .forTest(test, part: "translation", file: file), systemLanguages: systemLanguages)
    }
}

extension LayoutChoices {
    static func forTest(_ test: String, file: String = #fileID) -> LayoutChoices {
        LayoutChoices(defaults: .forTest(test, part: "layouts", file: file))
    }
}

extension HotKeyStore {
    static func forTest(_ test: String, file: String = #fileID) -> HotKeyStore {
        HotKeyStore(defaults: .forTest(test, part: "hotkeys", file: file))
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
        present: @escaping (NSWindow) -> Void = { _ in },
        file: String = #fileID
    ) -> SettingsWindowController {
        SettingsWindowController(
            hotKeys: hotKeys ?? HotKeyBindings(registrar: RecordingRegistrar(), store: .forTest(test, file: file)),
            permission: (macOS ?? PermissionRecorder(test: test, file: file)).permission(),
            loginItem: loginItem,
            makeTranslation: {
                TranslationSettingsModel(choices: .forTest(test, file: file), supportedLanguages: { [] })
            },
            makeLayouts: {
                LayoutSettingsModel(choices: .forTest(test, file: file), readEnabled: { [] }, openURL: { _ in })
            },
            openURL: { _ in }, openLoginItems: {}, present: present)
    }
}

extension PermissionRecorder {
    /// Accessibility already granted.
    static func trusted(test: String = #function, file: String = #fileID) -> PermissionRecorder {
        let macOS = PermissionRecorder(test: test, file: file)
        macOS.isTrusted = true
        return macOS
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
        layouts: [KeyboardLayout] = BuiltInLayouts().layouts, accessibilitySelection: String? = nil,
        smartTypeIsFrontmost: Bool = false, agrees: Bool = false
    ) -> LayoutFixAction {
        LayoutFixAction(
            makeCorrector: {
                LayoutCorrector(layouts: layouts, detector: LanguageDetector(scorers: [PhonotacticScorer()]))
            },
            clipboard: clipboard, permission: macOS.permission(), readSelection: { accessibilitySelection },
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
