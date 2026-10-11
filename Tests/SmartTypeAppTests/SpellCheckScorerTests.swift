import Testing

@testable import SmartTypeApp
@testable import SmartTypeCore

@Suite struct SpellCheckScorerTests {
    @Test func aWordTheDictionaryKnowsIsKnownInThatLanguage() {
        var asked: [String] = []
        let scorer = SpellCheckScorer(isSpelledCorrectly: { word, language in
            asked.append("\(language) \(word)")
            return true
        })

        #expect(scorer.score("привет", as: .russian) == .known)
        #expect(asked == ["ru привет"])
    }

    /// A misspelling may still be a name the dictionary has never seen, so it rules nothing out.
    @Test func aMisspellingIsOnlyUnknown() {
        let scorer = SpellCheckScorer(isSpelledCorrectly: { _, _ in false })
        #expect(scorer.score("ghbdtn", as: .english) == .unknown)
    }

    /// `NSSpellChecker` finds no misspelling in an empty string (measured, en and ru), so a token
    /// with no letters ("?!") would read as a known word in every language.
    @Test func anEmptyWordIsNeverKnown() {
        var asked = 0
        let scorer = SpellCheckScorer(isSpelledCorrectly: { _, _ in
            asked += 1
            return true
        })

        #expect(scorer.score("", as: .english) == .unknown)
        #expect(asked == 0)
    }

    /// The real dictionary, read-only: the words the corrector leans on (measured on macOS 27).
    @Test(arguments: [("привет", "ru", true), ("руддщ", "ru", false), ("hello", "en", true), ("ghbdtn", "en", false)])
    func theMacOSDictionary(_ word: String, _ language: String, _ isCorrect: Bool) {
        #expect(SpellCheckScorer.isSpelledCorrectly(word, in: language) == isCorrect)
    }
}
