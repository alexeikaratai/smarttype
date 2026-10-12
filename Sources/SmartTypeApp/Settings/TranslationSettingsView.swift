import SwiftUI

/// Settings ▸ Translation: the languages Translate works from and into. The card only shows
/// them, so a pick made here holds for every translation after it.
struct TranslationSettingsView: View {
    let settings: TranslationSettingsModel

    var body: some View {
        Form {
            Section {
                Picker(
                    String(
                        localized: "Translate from", comment: "Settings ▸ Translation: the language of the selection"),
                    selection: Binding(get: { settings.source }, set: { settings.pick(source: $0) })
                ) {
                    options
                }
                Picker(
                    String(
                        localized: "Translate into", comment: "Settings ▸ Translation: the language of the translation"),
                    selection: Binding(get: { settings.target }, set: { settings.pick(target: $0) })
                ) {
                    options
                }
            } footer: {
                Text(
                    String(
                        localized:
                            "Automatic: SmartType detects the language of the selection and translates it into the first of your languages it is not in. Your languages are in System Settings: General → Language & Region.",
                        comment: "Settings ▸ Translation: what Automatic means")
                )
                .foregroundStyle(.secondary)
            }
            .disabled(!AppCommand.translate.isAvailable)
            if !AppCommand.translate.isAvailable {
                Section {
                    Label(
                        String(
                            localized: "Translation needs macOS 26.",
                            comment: "Translation panel and Settings ▸ Translation: before macOS 26"),
                        systemImage: "exclamationmark.triangle")
                }
            }
        }
        .task { await settings.loadLanguages() }
    }

    @ViewBuilder private var options: some View {
        Text(String(localized: "Automatic", comment: "Settings ▸ Translation: no fixed language"))
            .tag(Locale.Language?.none)
        Divider()
        ForEach(settings.languages, id: \.self) { language in
            Text(language.displayName)
                .tag(Locale.Language?.some(language))
        }
    }
}
