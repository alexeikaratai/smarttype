import Foundation

/// Whether the welcome window has been closed, in UserDefaults under `com.smarttype.welcome.done`.
/// Absent for everyone before 0.3, so people updating see it once too (decided 2026-10-13).
struct FirstLaunch {
    private static let doneKey = "com.smarttype.welcome.done"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isDone: Bool {
        get { defaults.bool(forKey: Self.doneKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.doneKey) }
    }
}
