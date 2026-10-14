import Foundation

/// The language a translation goes into.
package enum TranslationTarget {
    /// The first of the person's languages the text is not in: their list puts the primary
    /// first, so text in it goes into the next. Text already in every one of them goes into
    /// English, and English text into Russian.
    package static func choose(for source: Locale.Language, preferred: [Locale.Language]) -> Locale.Language {
        if let target = preferred.first(where: { $0.languageCode != source.languageCode }) {
            return target
        }
        let english = Locale.Language(identifier: "en")
        return source.languageCode == english.languageCode ? Locale.Language(identifier: "ru") : english
    }
}
