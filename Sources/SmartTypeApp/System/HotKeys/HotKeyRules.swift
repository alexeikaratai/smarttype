import Carbon.HIToolbox

/// What a shortcut may be. Carbon registers nearly anything, ⌘C and ⌘Space included, and
/// reports a clash only within one process (measured), so the rules are SmartType's own.
enum HotKeyRules {
    static func problem(
        with combo: KeyCombo, for command: AppCommand, current: [AppCommand: KeyCombo], macOS: Set<KeyCombo>
    ) -> HotKeyProblem? {
        guard combo.key.isSupported else { return .unsupportedKey }
        guard combo.modifiers.isEnoughForAShortcut else { return .needsControlOrCommandOption }
        if macOS.contains(combo) {
            return .usedByMacOS
        }
        if let other = AppCommand.allCases.first(where: { $0 != command && current[$0] == combo }) {
            return .usedBy(other)
        }
        return nil
    }

    /// The shortcuts macOS has switched on: Spotlight, input sources, Mission Control and the
    /// rest (176 on this Mac, measured with `CopySymbolicHotKeys`).
    static func macOSShortcuts() -> Set<KeyCombo> {
        var symbolic: Unmanaged<CFArray>?
        guard CopySymbolicHotKeys(&symbolic) == noErr,
            let entries = symbolic?.takeRetainedValue() as? [[String: Any]]
        else { return [] }
        return shortcuts(
            from: entries.compactMap { entry in
                guard entry[kHISymbolicHotKeyEnabled as String] as? Bool == true,
                    let code = entry[kHISymbolicHotKeyCode as String] as? Int,
                    let modifiers = entry[kHISymbolicHotKeyModifiers as String] as? Int
                else { return nil }
                return (code: code, carbonModifiers: modifiers)
            })
    }

    /// Key codes and Carbon modifiers, as `CopySymbolicHotKeys` lists them, with fn dropped:
    /// 106 of the 176 switched on carry it (measured), and a SmartType shortcut never does.
    static func shortcuts(from entries: [(code: Int, carbonModifiers: Int)]) -> Set<KeyCombo> {
        Set(
            entries.compactMap { entry in
                guard let code = UInt16(exactly: entry.code), let flags = UInt32(exactly: entry.carbonModifiers)
                else { return nil }
                return KeyCombo(key: Key(code: code), modifiers: Modifiers(carbonFlags: flags))
            })
    }
}

// MARK: - HotKeyProblem

/// Why a combination cannot be a shortcut.
enum HotKeyProblem: Equatable {
    /// Esc, a modifier or a keypad key: a key `Key` has no name for.
    case unsupportedKey
    /// Neither ⌃ nor ⌘ with ⌥; `Modifiers.isEnoughForAShortcut` says why.
    case needsControlOrCommandOption
    case usedByMacOS
    case usedBy(AppCommand)

    var message: String {
        switch self {
        case .unsupportedKey:
            String(localized: "This key can’t be part of a shortcut.", comment: "Settings ▸ Shortcuts: refused key")
        case .needsControlOrCommandOption:
            String(
                localized: "Hold ⌃, or ⌘ together with ⌥.", comment: "Settings ▸ Shortcuts: refused modifiers")
        case .usedByMacOS:
            String(localized: "macOS already uses it.", comment: "Settings ▸ Shortcuts: a system shortcut")
        case .usedBy(let command):
            String(localized: "Already used by", comment: "Settings ▸ Shortcuts: before the other command's name")
                + " " + command.title
        }
    }
}
