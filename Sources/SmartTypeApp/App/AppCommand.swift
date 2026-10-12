import Foundation

/// Everything a person can ask SmartType to do. Hotkeys and the menu are built from this
/// list, so a new command cannot reach one front door and miss the other.
nonisolated enum AppCommand: CaseIterable, Sendable {
    case fixLayout
    case translate

    var title: String {
        switch self {
        case .fixLayout:
            String(localized: "Fix Layout", comment: "Command: retype the selection in the other keyboard layout")
        case .translate: String(localized: "Translate", comment: "Command: translate the selection")
        }
    }

    /// Whether this Mac can run the command: translation needs Apple's engine, from macOS 26.
    var isAvailable: Bool {
        switch self {
        case .fixLayout:
            return true
        case .translate:
            if #available(macOS 26, *) {
                return true
            }
            return false
        }
    }

    /// What a Mac needs for the command, said where it cannot run.
    var requirement: String? {
        switch self {
        case .fixLayout: nil
        case .translate: String(localized: "Needs macOS 26", comment: "Menu: why Translate is greyed out")
        }
    }

    /// ⌃⌥⇧ rather than ⌃⌥ (decided 2026-10-12): one key more, so a stray press in another app is
    /// less likely to fire it. A person can set their own in Settings ▸ Shortcuts.
    var defaultHotKey: KeyCombo {
        switch self {
        case .fixLayout: KeyCombo(key: .l, modifiers: [.control, .option, .shift])
        case .translate: KeyCombo(key: .t, modifiers: [.control, .option, .shift])
        }
    }

    /// The command's name in stored settings. Frozen: renaming a case must not lose the shortcut
    /// a person set for it.
    var storageName: String {
        switch self {
        case .fixLayout: "fixLayout"
        case .translate: "translate"
        }
    }
}
