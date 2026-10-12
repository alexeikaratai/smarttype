import Foundation

/// The language a translation goes into.
package enum TranslationTarget {
    /// The person's pick, unless the text is already in it; otherwise the first of their
    /// languages the text is not in. Text already in every one of them goes into English,
    /// and English text into Russian.
    package static func choose(
        for source: Locale.Language, preferred: [Locale.Language], picked: Locale.Language? = nil
    ) -> Locale.Language {
        let candidates = (picked.map { [$0] } ?? []) + preferred
        if let target = candidates.first(where: { $0.languageCode != source.languageCode }) {
            return target
        }
        let english = Locale.Language(identifier: "en")
        return source.languageCode == english.languageCode ? Locale.Language(identifier: "ru") : english
    }
}
