import Testing

@testable import SmartTypeApp
@testable import SmartTypeCore

@Suite struct SpellCheckScorerTests {
    @Test func aWordTheDictionaryKnowsIsKnownInThatLanguage() {
        var asked: [String] = []
        let scorer = SpellCheckScorer(
            isSpelledCorrectly: { word, language in
                asked.append("\(language) \(word)")
                return true
            }, hasDictionary: { _ in true })

        #expect(scorer.score("привет", as: .russian) == .known)
        #expect(asked == ["ru привет"])
    }

    /// A misspelling may still be a name the dictionary has never seen, so it rules nothing out.
    @Test func aMisspellingIsOnlyUnknown() {
        let scorer = SpellCheckScorer(isSpelledCorrectly: { _, _ in false }, hasDictionary: { _ in true })
        #expect(scorer.score("ghbdtn", as: .english) == .unknown)
    }

    /// `NSSpellChecker` finds no misspelling in an empty string (measured, en and ru), so a token
    /// with no letters ("?!") would read as a known word in every language.
    @Test func anEmptyWordIsNeverKnown() {
        var asked = 0
        let scorer = SpellCheckScorer(
            isSpelledCorrectly: { _, _ in
                asked += 1
                return true
            }, hasDictionary: { _ in true })

        #expect(scorer.score("", as: .english) == .unknown)
        #expect(asked == 0)
    }

    /// Without a dictionary for the language, macOS finds no misspelling in anything ("ghbdtn" in
    /// "xx" or "zh-Hans", measured), which would make every word known: Kazakh, Georgian and
    /// Armenian layouts have no dictionary on macOS 27.
    @Test func aLanguageWithoutADictionaryKnowsNothing() {
        var asked = 0
        let scorer = SpellCheckScorer(
            isSpelledCorrectly: { _, _ in
                asked += 1
                return true
            }, hasDictionary: { $0 != "kk" })

        #expect(scorer.score("ghbdtn", as: Language(code: "kk")) == .unknown)
        #expect(asked == 0)
    }

    /// macOS lists its dictionaries by language and region: "en", "en_GB", "pt_BR" (measured).
    @Test(arguments: [("uk", true), ("pl", true), ("en", true), ("pt-BR", true), ("kk", false), ("zh-Hans", false)])
    func theMacOSDictionaries(_ language: String, _ hasOne: Bool) {
        #expect(SpellCheckScorer.hasDictionary(for: language) == hasOne)
    }

    /// The real dictionary, read-only: the words the corrector leans on (measured on macOS 27).
    @Test(arguments: [("привет", "ru", true), ("руддщ", "ru", false), ("hello", "en", true), ("ghbdtn", "en", false)])
    func theMacOSDictionary(_ word: String, _ language: String, _ isCorrect: Bool) {
        #expect(SpellCheckScorer.isSpelledCorrectly(word, in: language) == isCorrect)
    }
}
