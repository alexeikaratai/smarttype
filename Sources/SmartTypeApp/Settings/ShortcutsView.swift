import SwiftUI

/// Settings ▸ Shortcuts: each command's shortcut. Click one and press the new keys.
struct ShortcutsView: View {
    let model: ShortcutsViewModel

    var body: some View {
        Form {
            Section {
                ForEach(AppCommand.allCases, id: \.self) { command in
                    LabeledContent(command.title) {
                        ShortcutField(command: command, model: model)
                    }
                    if model.recording == command, let problem = model.problem {
                        Text(problem.message)
                            .foregroundStyle(.red)
                    } else if model.refused.contains(command) {
                        Text(String(localized: "not registered", comment: "After a shortcut macOS refused to register"))
                            .foregroundStyle(.red)
                    }
                }
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        String(
                            localized: "They work in any app and in any keyboard layout.",
                            comment: "Settings ▸ Shortcuts: intro")
                    )
                    .foregroundStyle(.secondary)
                    Text(
                        String(
                            localized:
                                "Click a shortcut, then press the new keys. Esc cancels; ⌫ leaves the command without one.",
                            comment: "Settings ▸ Shortcuts: how to change a shortcut")
                    )
                    .foregroundStyle(.secondary)
                    Text(
                        String(
                            localized:
                                "Another app may listen for the same keys, and macOS does not say so. If a shortcut does nothing, pick another.",
                            comment: "Settings ▸ Shortcuts: clashes with other apps go unreported")
                    )
                    .foregroundStyle(.tertiary)
                }
            }
        }
        .onDisappear(perform: model.stopRecording)
    }
}
