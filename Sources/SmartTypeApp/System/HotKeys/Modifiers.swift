import AppKit
import Carbon.HIToolbox

/// Modifier keys, convertible to and from what Carbon and AppKit each use. All four views come
/// from one table, so a modifier cannot be spelled in one and forgotten in another. The raw
/// values are stored with every shortcut, so they are frozen.
nonisolated struct Modifiers: OptionSet, Hashable, Sendable {
    static let control = Modifiers(rawValue: 1 << 0)
    static let option = Modifiers(rawValue: 1 << 1)
    static let shift = Modifiers(rawValue: 1 << 2)
    static let command = Modifiers(rawValue: 1 << 3)
    static let all: Modifiers = [.control, .option, .shift, .command]

    private static let spellings = [
        Spelling(modifier: .control, symbol: "⌃", carbon: UInt32(controlKey), event: .control),
        Spelling(modifier: .option, symbol: "⌥", carbon: UInt32(optionKey), event: .option),
        Spelling(modifier: .shift, symbol: "⇧", carbon: UInt32(shiftKey), event: .shift),
        Spelling(modifier: .command, symbol: "⌘", carbon: UInt32(cmdKey), event: .command),
    ]

    let rawValue: UInt8

    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    /// AppKit's flags, without Caps Lock, fn or anything else a shortcut does not hold.
    init(eventFlags: NSEvent.ModifierFlags) {
        self = Self.spellings.reduce(into: []) { if eventFlags.contains($1.event) { $0.insert($1.modifier) } }
    }

    /// Carbon's flags. macOS's own shortcuts also carry fn (0x20000; measured), which is dropped.
    init(carbonFlags: UInt32) {
        self = Self.spellings.reduce(into: []) { if carbonFlags & $1.carbon != 0 { $0.insert($1.modifier) } }
    }

    /// ⌃, or ⌘ together with ⌥. ⌘ alone would take keys every app uses: a global ⌘C would stop
    /// copying everywhere. Some macOS 15 builds refuse ⌥ or ⌥⇧ alone. Both the rules for a new
    /// shortcut and the reading of a stored one ask this, so the two cannot disagree.
    var isEnoughForAShortcut: Bool {
        contains(.control) || isSuperset(of: [.command, .option])
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
}
