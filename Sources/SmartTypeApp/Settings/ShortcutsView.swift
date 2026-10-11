import SwiftUI

/// Settings ▸ Shortcuts: what each command is bound to. Read-only until Phase 3.
struct ShortcutsView: View {
    let shortcuts: [Shortcut]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                String(
                    localized: "They work in any app and in any keyboard layout.",
                    comment: "Settings ▸ Shortcuts: intro")
            )
            .foregroundStyle(.secondary)
            ForEach(shortcuts) { shortcut in
                HStack {
                    Text(shortcut.title)
                    Spacer()
                    if !shortcut.isRegistered {
                        Text(String(localized: "not registered", comment: "After a shortcut macOS refused to register"))
                            .foregroundStyle(.red)
                    }
                    Text(verbatim: shortcut.keys)
                        .monospaced()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                }
            }
            Text(
                String(
                    localized: "Changing shortcuts comes in a later version",
                    comment: "Shortcuts submenu and Settings ▸ Shortcuts")
            )
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
    }
}

/// One row of the list: a command, its keys, and whether macOS accepted them.
struct Shortcut: Identifiable {
    let command: AppCommand
    let isRegistered: Bool

    var id: AppCommand { command }
    var title: String { command.title }
    var keys: String { command.defaultHotKey.displayString }

    static func all(refused: Set<AppCommand>) -> [Shortcut] {
        AppCommand.allCases.map { Shortcut(command: $0, isRegistered: !refused.contains($0)) }
    }
}
