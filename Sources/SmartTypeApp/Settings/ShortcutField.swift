import SwiftUI

/// A command's shortcut, as a button: clicked, it records the next keys pressed. Beside it, a
/// button back to the default once the shortcut is another.
struct ShortcutField: View {
    let command: AppCommand
    let model: ShortcutsViewModel

    var body: some View {
        HStack(spacing: 6) {
            Button {
                model.toggleRecording(command)
            } label: {
                Text(verbatim: title)
                    .monospaced()
                    .frame(minWidth: 120)
            }
            .cardButtonStyle()
            if !model.isDefault(command) {
                // The words stay the label VoiceOver reads, as on the panel's Copy button.
                Button {
                    model.reset(command)
                } label: {
                    Label(resetTitle, systemImage: "arrow.counterclockwise")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .help(resetTitle)
            }
        }
    }

    private var resetTitle: String {
        String(
            localized: "Back to the default shortcut",
            comment: "Settings ▸ Shortcuts: the reset button, read by VoiceOver and shown as its tooltip")
    }

    private var title: String {
        guard model.recording == command else {
            return model.shortcuts[command]?.displayString
                ?? String(localized: "None", comment: "Settings ▸ Shortcuts: a command without a shortcut")
        }
        guard model.heldModifiers.isEmpty else { return model.heldModifiers.symbols + "…" }
        return String(localized: "Type Shortcut…", comment: "Settings ▸ Shortcuts: while recording")
    }
}
