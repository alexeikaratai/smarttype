import AppKit
import Carbon.HIToolbox

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
    /// another version or a hand edit is never read as the wrong keys.
    init?(storage: [String: Int]) {
        guard let code = storage["keyCode"].flatMap(UInt16.init(exactly:)),
            let bits = storage["modifiers"].flatMap(UInt8.init(exactly:)),
            Modifiers.all.isSuperset(of: Modifiers(rawValue: bits))
        else { return nil }
        let key = Key(code: code)
        guard key.isSupported else { return nil }
        self.init(key: key, modifiers: Modifiers(rawValue: bits))
    }
}

/// Modifier keys, convertible to and from what Carbon and AppKit each use. All four views come
/// from one table, so a modifier cannot be spelled in one and forgotten in another. The raw
/// values are stored with every shortcut, so they are frozen.
nonisolated struct Modifiers: OptionSet, Hashable, Sendable {
    let rawValue: UInt8

    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    static let control = Modifiers(rawValue: 1 << 0)
    static let option = Modifiers(rawValue: 1 << 1)
    static let shift = Modifiers(rawValue: 1 << 2)
    static let command = Modifiers(rawValue: 1 << 3)
    static let all: Modifiers = [.control, .option, .shift, .command]

    /// AppKit's flags, without Caps Lock, fn or anything else a shortcut does not hold.
    init(eventFlags: NSEvent.ModifierFlags) {
        self = Self.spellings.reduce(into: []) { if eventFlags.contains($1.event) { $0.insert($1.modifier) } }
    }

    /// Carbon's flags. macOS's own shortcuts also carry fn (0x20000; measured), which is dropped.
    init(carbonFlags: UInt32) {
        self = Self.spellings.reduce(into: []) { if carbonFlags & $1.carbon != 0 { $0.insert($1.modifier) } }
    }

    /// In the order macOS prints them: ⌃⌥⇧⌘.
    var symbols: String {
        present.map(\.symbol).joined()
    }

    var carbonFlags: UInt32 {
        present.reduce(0) { $0 | $1.carbon }
    }

    var eventFlags: NSEvent.ModifierFlags {
        present.reduce(into: []) { $0.formUnion($1.event) }
    }

    private var present: [Spelling] {
        Self.spellings.filter { contains($0.modifier) }
    }

    private struct Spelling: Sendable {
        let modifier: Modifiers
        let symbol: String
        let carbon: UInt32
        let event: NSEvent.ModifierFlags
    }

    private static let spellings = [
        Spelling(modifier: .control, symbol: "⌃", carbon: UInt32(controlKey), event: .control),
        Spelling(modifier: .option, symbol: "⌥", carbon: UInt32(optionKey), event: .option),
        Spelling(modifier: .shift, symbol: "⇧", carbon: UInt32(shiftKey), event: .shift),
        Spelling(modifier: .command, symbol: "⌘", carbon: UInt32(cmdKey), event: .command),
    ]
}
