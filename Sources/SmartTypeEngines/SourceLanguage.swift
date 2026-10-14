import Foundation
import NaturalLanguage

/// The language a text is in, for translation, recognized on the Mac.
///
/// Sentences come back sure: 1.00 for Russian, German and French (measured). Single words do
/// not: "hello" scores 0.13, and "привет" is taken for Bulgarian at 0.53. So below 0.9 the
/// person's own languages go in as hints, which settles those, at the price of reading a lone
/// foreign word ("Bonjour") as one of them; Settings ▸ Languages lets the person pick the
/// source then.
package enum SourceLanguage {
    package static func detect(_ text: String, preferred: [Locale.Language]) -> Locale.Language? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        if let (language, confidence) = recognizer.languageHypotheses(withMaximum: 1).first, confidence >= 0.9 {
            return Locale.Language(identifier: language.rawValue)
        }
        let hinted = Set(preferred.compactMap { $0.languageCode?.identifier })
        recognizer.reset()
        recognizer.languageHints = Dictionary(
            uniqueKeysWithValues: hinted.map { (NLLanguage(rawValue: $0), 1 / Double(hinted.count)) })
        recognizer.processString(text)
        return recognizer.dominantLanguage.map { Locale.Language(identifier: $0.rawValue) }
    }
}
