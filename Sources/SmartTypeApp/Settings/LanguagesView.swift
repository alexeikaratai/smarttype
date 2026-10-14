import SwiftUI

/// Settings ▸ Languages: the person's languages, the primary first, which every translation
/// follows, and "Read text as" for text recognition keeps getting wrong.
struct LanguagesView: View {
    let translation: TranslationSettingsModel

    var body: some View {
        Form {
            // The note stays readable; only what it explains is greyed out.
            Group {
                languagesSection
                readTextAsSection
            }
            .disabled(!AppCommand.translate.isAvailable)
            if !AppCommand.translate.isAvailable {
                Section {
                    Label(
                        String(
                            localized: "Translation needs macOS 26.",
                            comment: "Translation panel and Settings ▸ Languages: before macOS 26"),
                        systemImage: "exclamationmark.triangle")
                }
            }
        }
        .task { await translation.loadLanguages() }
    }

    // MARK: - Private

    private var languagesSection: some View {
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
            note(
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

    private var readTextAsSection: some View {
        Section {
            Picker(
                String(localized: "Read text as", comment: "Settings ▸ Languages: the language of the selection"),
                selection: Binding(get: { translation.source }, set: { translation.pick(source: $0) })
            ) {
                Text(String(localized: "Automatic", comment: "Settings ▸ Languages: no fixed language"))
                    .tag(Locale.Language?.none)
                Divider()
                ForEach(translation.readableLanguages, id: \.self) { language in
                    Text(language.displayName).tag(Locale.Language?.some(language))
                }
            }
        } footer: {
            note(
                String(
                    localized:
                        "Automatic recognizes the language of each selection. Pick one only if it keeps getting yours wrong.",
                    comment: "Settings ▸ Languages: what Automatic means for Read text as"))
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
