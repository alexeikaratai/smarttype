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

    var defaultHotKey: KeyCombo {
        switch self {
        case .fixLayout: KeyCombo(key: .l, modifiers: [.control, .option])
        case .translate: KeyCombo(key: .t, modifiers: [.control, .option])
        }
    }
}
