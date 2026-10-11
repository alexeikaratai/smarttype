import AppKit
import SmartTypeCore

/// The macOS dictionary as one more opinion for the language detector. A word spelled
/// correctly in a language is `known` there; a misspelling is only `unknown`, since it may be
/// a name the dictionary has never seen.
struct SpellCheckScorer: WordScorer {
    private let check: (String, String) -> Bool

    init(isSpelledCorrectly: @escaping (String, String) -> Bool = { SpellCheckScorer.isSpelledCorrectly($0, in: $1) }) {
        check = isSpelledCorrectly
    }

    func score(_ word: String, as language: Language) -> Plausibility {
        guard !word.isEmpty else { return .unknown }
        return check(word, language.code) ? .known : .unknown
    }

    /// `NSSpellChecker` belongs to the main thread, which is why the detector runs there.
    static func isSpelledCorrectly(_ word: String, in language: String) -> Bool {
        let misspelling = NSSpellChecker.shared.checkSpelling(
            of: word, startingAt: 0, language: language, wrap: false, inSpellDocumentWithTag: 0, wordCount: nil)
        return misspelling.location == NSNotFound
    }
}
