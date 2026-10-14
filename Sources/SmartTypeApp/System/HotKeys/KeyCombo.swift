/// A physical key plus modifiers. Key codes name positions, not letters, so ⌃⌥⇧L fires
/// whichever layout is active — exactly what a layout fixer needs.
nonisolated struct KeyCombo: Hashable, Sendable {
    let key: Key
    let modifiers: Modifiers

    init(key: Key, modifiers: Modifiers) {
        self.key = key
        self.modifiers = modifiers
    }

    /// How macOS writes it in menus: ⌃⌥⇧L.
    var displayString: String { modifiers.symbols + key.label }

    /// How UserDefaults keeps it. Frozen: a change would lose every shortcut people have set.
    var storage: [String: Int] {
        ["keyCode": Int(key.code), "modifiers": Int(modifiers.rawValue)]
    }

    /// `nil` for anything this version cannot use as a shortcut, so a stored value from
    /// another version or a hand edit is never read as the wrong keys, nor as a bare key that
    /// would take a letter from every app.
    init?(storage: [String: Int]) {
        guard let code = storage["keyCode"].flatMap(UInt16.init(exactly:)),
            let bits = storage["modifiers"].flatMap(UInt8.init(exactly:)),
            Modifiers.all.isSuperset(of: Modifiers(rawValue: bits)),
            Modifiers(rawValue: bits).isEnoughForAShortcut
        else { return nil }
        let key = Key(code: code)
        guard key.isSupported else { return nil }
        self.init(key: key, modifiers: Modifiers(rawValue: bits))
    }
}
