import AppKit
import Testing

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

/// Expects each object freed, naming the one still alive. SwiftUI lets a closed window's view
/// models go on a later turn of the run loop, which a busy runner put past 2 s (CI, and here
/// with every core busy), so each gets 10 s; one that something keeps still fails.
func expectFreed(
    _ objects: [(name: String, isFreed: () -> Bool)], sourceLocation: SourceLocation = #_sourceLocation
) async {
    for object in objects {
        let isFreed = await waitUntil(timeout: .seconds(10), object.isFreed)
        #expect(isFreed, "\(object.name) is still alive", sourceLocation: sourceLocation)
    }
}

extension UserDefaults {
    /// A defaults domain per test and per part, emptied first and never the app's own. Parts keep
    /// the fakes of one test from emptying each other's domain. Named by a path, it is kept in
    /// the temporary folder rather than in ~/Library/Preferences (measured).
    static func forTest(_ test: String, part: String, file: String = #fileID) -> UserDefaults {
        let name = "com.smarttype.tests.\(file).\(test).\(part)".replacingOccurrences(of: "/", with: ".")
        let suite = FileManager.default.temporaryDirectory.appending(path: name).path
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

extension FirstLaunch {
    /// Done unless told otherwise, so only the tests about it see the welcome window.
    static func forTest(_ test: String, isDone: Bool = true, file: String = #fileID) -> FirstLaunch {
        let firstLaunch = FirstLaunch(defaults: .forTest(test, part: "welcome", file: file))
        firstLaunch.isDone = isDone
        return firstLaunch
    }
}

extension HotKeyStore {
    static func forTest(_ test: String, file: String = #fileID) -> HotKeyStore {
        HotKeyStore(defaults: .forTest(test, part: "hotkeys", file: file))
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

// The view models Settings and the welcome window are built from, on private defaults.

extension TranslationSettingsModel {
    /// An engine that knows no languages.
    static func forTest(_ test: String, file: String = #fileID) -> TranslationSettingsModel {
        TranslationSettingsModel(choices: .forTest(test, file: file), supportedLanguages: { [] })
    }
}

extension LayoutSettingsModel {
    static func forTest(
        _ test: String, enabled: @escaping () -> [InputSourceLayout] = { [] }, file: String = #fileID
    ) -> LayoutSettingsModel {
        LayoutSettingsModel(choices: .forTest(test, file: file), readEnabled: enabled, openURL: { _ in })
    }
}

extension ShortcutsViewModel {
    /// The default shortcuts registered, and keys pressed through `keyboard`.
    static func forTest(
        _ registrar: RecordingRegistrar, _ keyboard: KeyMonitorRecorder, macOS: Set<KeyCombo> = [],
        test: String = #function, file: String = #fileID
    ) -> ShortcutsViewModel {
        let bindings = HotKeyBindings(registrar: registrar, store: .forTest(test, file: file))
        bindings.apply()
        return ShortcutsViewModel(bindings: bindings, macOSShortcuts: { macOS }, watchKeys: { keyboard.watch($0) })
    }
}
