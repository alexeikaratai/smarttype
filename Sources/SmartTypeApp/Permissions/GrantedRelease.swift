import Foundation

/// The release that last had the Accessibility permission, in UserDefaults under
/// `com.smarttype.accessibility.grantedRelease`, as "0.3.4 (11)". macOS keeps a grant for the
/// code it was given to, and every release is signed anew: a new one reads as not trusted while
/// the old entry stays (measured with a probe; tccd: "Failed to match existing code requirement").
struct GrantedRelease {
    private static let key = "com.smarttype.accessibility.grantedRelease"

    private let defaults: UserDefaults
    private let current: String

    init(defaults: UserDefaults = .standard, current: String = AppInfo().release) {
        self.defaults = defaults
        self.current = current
    }

    func remember() {
        defaults.set(current, forKey: Self.key)
    }

    /// An earlier release that had the permission, forgotten as it is told, so the update that
    /// took it is told once.
    func takeEarlier() -> String? {
        guard let earlier = defaults.string(forKey: Self.key), earlier != current else { return nil }
        defaults.removeObject(forKey: Self.key)
        return earlier
    }
}
