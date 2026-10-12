import Foundation

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
