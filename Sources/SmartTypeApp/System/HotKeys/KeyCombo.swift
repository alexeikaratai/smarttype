import AppKit
import Carbon.HIToolbox

/// A physical key plus modifiers. Key codes name positions, not letters, so ⌃⌥L fires
/// whichever layout is active — exactly what a layout fixer needs.
nonisolated struct KeyCombo: Hashable, Sendable, Codable {
    let key: Key
    let modifiers: Modifiers

    init(key: Key, modifiers: Modifiers) {
        self.key = key
        self.modifiers = modifiers
    }

    /// How macOS writes it in menus: ⌃⌥L.
    var displayString: String { modifiers.symbols + key.label }
}

/// A key by its `kVK_*` code, with the label a U.S. keyboard prints on it.
nonisolated struct Key: Hashable, Sendable, Codable {
    let code: UInt16
    let label: String

    static let l = Key(code: UInt16(kVK_ANSI_L), label: "L")
    static let t = Key(code: UInt16(kVK_ANSI_T), label: "T")
}

/// Modifier keys, convertible to what Carbon and AppKit each expect. All three views come
/// from one table, so a modifier cannot be spelled in one and forgotten in another.
nonisolated struct Modifiers: OptionSet, Hashable, Sendable, Codable {
    let rawValue: UInt8

    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    static let control = Modifiers(rawValue: 1 << 0)
    static let option = Modifiers(rawValue: 1 << 1)
    static let shift = Modifiers(rawValue: 1 << 2)
    static let command = Modifiers(rawValue: 1 << 3)

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
