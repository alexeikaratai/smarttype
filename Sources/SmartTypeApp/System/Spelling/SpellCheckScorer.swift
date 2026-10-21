import AppKit
import SmartTypeCore

/// The macOS dictionary as one more opinion for the language detector. A word spelled
/// correctly in a language is `known` there; a misspelling is only `unknown`, since it may be
/// a name the dictionary has never seen.
struct SpellCheckScorer: WordScoring {
    private let check: (String, String) -> Bool
    private let hasDictionary: (String) -> Bool

    init(
        isSpelledCorrectly: @escaping (String, String) -> Bool = { SpellCheckScorer.isSpelledCorrectly($0, in: $1) },
        hasDictionary: @escaping (String) -> Bool = { SpellCheckScorer.hasDictionary(for: $0) }
    ) {
        check = isSpelledCorrectly
        self.hasDictionary = hasDictionary
    }

    /// `NSSpellChecker` belongs to the main thread, which is why the detector runs there.
    static func isSpelledCorrectly(_ word: String, in language: String) -> Bool {
        let misspelling = NSSpellChecker.shared.checkSpelling(
            of: word, startingAt: 0, language: language, wrap: false, inSpellDocumentWithTag: 0, wordCount: nil)
        return misspelling.location == NSNotFound
    }

    /// macOS lists its dictionaries as "en", "en_GB", "pt_BR" (measured: 46 on macOS 27, with uk,
    /// pl, he and ar, and no kk, ka or hy).
    static func hasDictionary(for language: String) -> Bool {
        NSSpellChecker.shared.availableLanguages.contains(language.replacingOccurrences(of: "-", with: "_"))
    }

    /// A language without a dictionary is never asked: macOS then finds no misspelling in
    /// anything ("ghbdtn" in "xx" or "zh-Hans", measured), and every word would read as known.
    func score(_ word: String, as language: Language) -> Plausibility {
        guard !word.isEmpty, hasDictionary(language.code) else { return .unknown }
        return check(word, language.code) ? .known : .unknown
    }
}
