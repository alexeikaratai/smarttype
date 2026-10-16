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
