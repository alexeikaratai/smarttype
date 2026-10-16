import SwiftUI

/// Settings ▸ Languages: the layouts Fix Layout works between, then the person's languages, the
/// primary first, which every translation follows, and "Read text as" for text recognition
/// keeps getting wrong.
struct LanguagesView: View {
    let translation: TranslationSettingsModel
    let layouts: LayoutSettingsModel

    var body: some View {
        Form {
            FixLayoutSection(layouts: layouts)
            // The note stays readable; only what it explains is greyed out.
            Group {
                TranslationLanguagesSection(translation: translation)
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
            SettingsNote(
                String(
                    localized:
                        "Automatic recognizes the language of each selection. Pick one only if it keeps getting yours wrong.",
                    comment: "Settings ▸ Languages: what Automatic means for Read text as"))
        }
    }
}
