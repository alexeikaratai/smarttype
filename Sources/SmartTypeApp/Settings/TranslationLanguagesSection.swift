import SwiftUI

/// The person's languages, the primary first, which every translation follows: with Make
/// Primary, a remove button (disabled for the last one) and Add Language…. In Settings ▸
/// Languages and in the welcome window.
struct TranslationLanguagesSection: View {
    let translation: TranslationSettingsModel

    var body: some View {
        Section {
            ForEach(translation.languages, id: \.self) { language in
                row(for: language)
            }
            Menu(String(localized: "Add Language…", comment: "Settings ▸ Languages: adds a language to the list")) {
                ForEach(translation.addable, id: \.self) { language in
                    Button(language.displayName) { translation.add(language) }
                }
            }
            .disabled(translation.addable.isEmpty)
        } header: {
            Text(String(localized: "Your languages", comment: "Settings ▸ Languages: the list's heading"))
        } footer: {
            SettingsNote(
                String(
                    localized:
                        "Text in any other language is translated into the primary one, and text in the primary one into the next. The list also helps recognize short words.",
                    comment: "Settings ▸ Languages: how the list decides a translation"))
        }
    }

    private func row(for language: Locale.Language) -> some View {
        HStack {
            Text(language.displayName)
            if translation.isPrimary(language) {
                Text(String(localized: "Primary", comment: "Settings ▸ Languages: the language translations go into"))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !translation.isPrimary(language) {
                Button(String(localized: "Make Primary", comment: "Settings ▸ Languages: moves a language to the top"))
                {
                    translation.makePrimary(language)
                }
            }
            // The word stays the label VoiceOver reads, as on the panel's Copy button.
            Button {
                translation.remove(language)
            } label: {
                Label(
                    String(localized: "Remove", comment: "Settings ▸ Languages: removes a language from the list"),
                    systemImage: "minus.circle"
                )
                .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .help(String(localized: "Remove", comment: "Settings ▸ Languages: removes a language from the list"))
            .disabled(!translation.canRemove)
        }
    }
}
