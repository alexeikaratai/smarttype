import Foundation
import SmartTypeCore

/// The layouts the person switched off for Fix Layout in Settings ▸ Languages, in UserDefaults
/// under `com.smarttype.layouts.switchedOff`. What is kept is what is off, so every other layout
/// enabled in macOS is fixed between, one enabled there later included.
struct LayoutChoices {
    private static let switchedOffKey = "com.smarttype.layouts.switchedOff"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var switchedOff: Set<String> {
        get { Set(defaults.stringArray(forKey: Self.switchedOffKey) ?? []) }
        nonmutating set { defaults.set(newValue.sorted(), forKey: Self.switchedOffKey) }
    }

    /// The layouts enabled in macOS that Fix Layout works between, in macOS's order: the fix's
    /// tables and the names the menu shows both come from here, so the two cannot drift.
    func switchedOn(_ enabled: [InputSourceLayout] = InputSourceLayouts.read()) -> [InputSourceLayout] {
        let switchedOff = switchedOff
        return enabled.filter { !switchedOff.contains($0.layout.id) }
    }
}
