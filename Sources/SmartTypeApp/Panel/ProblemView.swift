import SwiftUI

/// What the translation card says when there is no translation, and what to do about it.
struct ProblemView: View {
    let problem: TranslationViewModel.Problem
    let openTranslationLanguages: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
            if problem == .notDownloaded {
                Button(
                    String(
                        localized: "Open Translation Languages…", comment: "Translation panel: opens System Settings"),
                    action: openTranslationLanguages
                )
                .cardButtonStyle()
            }
        }
    }

    private var message: String {
        switch problem {
        case .notDownloaded:
            String(
                localized:
                    "These languages are not downloaded yet: General → Language & Region → Translation Languages… in System Settings.",
                comment: "Translation panel: the language pair needs downloading")
        case .unsupported:
            String(localized: "Apple does not translate between these languages.", comment: "Translation panel")
        case .unavailable:
            String(
                localized: "Translation needs macOS 26.",
                comment: "Translation panel and Settings ▸ Languages: before macOS 26")
        case .tooLong:
            String(localized: "Too long to translate here: over 2,000 characters.", comment: "Translation panel")
        case .failed:
            String(localized: "The translation did not work. Try again.", comment: "Translation panel")
        }
    }
}
