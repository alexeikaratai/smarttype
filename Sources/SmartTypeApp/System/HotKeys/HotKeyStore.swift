import Foundation

/// The shortcut the person set for each command. UserDefaults keeps one entry per command,
/// `com.smarttype.shortcut.<command>`: `{keyCode, modifiers}` for a shortcut, `{}` when it was
/// cleared, and nothing while it is the default, so a later default reaches everyone who never
/// changed it. Frozen: a change would lose every shortcut people have set.
struct HotKeyStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    static func key(for command: AppCommand) -> String {
        "com.smarttype.shortcut." + command.storageName
    }

    /// `nil` when the person cleared it. A value this version cannot read means the default.
    func shortcut(for command: AppCommand) -> KeyCombo? {
        guard let stored = defaults.object(forKey: Self.key(for: command)) as? [String: Int] else {
            return command.defaultHotKey
        }
        guard !stored.isEmpty else { return nil }
        return KeyCombo(storage: stored) ?? command.defaultHotKey
    }

    /// `nil` clears it. The default is stored as no entry at all.
    func set(_ combo: KeyCombo?, for command: AppCommand) {
        guard combo != command.defaultHotKey else { return reset(command) }
        defaults.set(combo?.storage ?? [:], forKey: Self.key(for: command))
    }

    func reset(_ command: AppCommand) {
        defaults.removeObject(forKey: Self.key(for: command))
    }

    func isDefault(_ command: AppCommand) -> Bool {
        defaults.object(forKey: Self.key(for: command)) == nil
    }
}
