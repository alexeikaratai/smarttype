import Testing

@testable import SmartTypeCore

@Suite struct LanguageDetectorTests {
    @Test(arguments: [
        ("Привет, как дела?", Language.russian),
        ("Hello, world", .english),
        ("Привет, world", .russian),
    ])
    func theScriptWithTheMostLettersWins(_ text: String, _ expected: Language) {
        let detector = LanguageDetector(scorers: [])
        #expect(detector.dominantLanguage(of: text, among: [.english, .russian]) == expected)
    }

    @Test func aTieGoesToTheEarlierCandidate() {
        let detector = LanguageDetector(scorers: [])
        #expect(detector.dominantLanguage(of: "ok, да", among: [.english, .russian]) == .english)
        #expect(detector.dominantLanguage(of: "ok, да", among: [.russian, .english]) == .russian)
    }

    @Test func textWithoutLettersHasNoLanguage() {
        #expect(LanguageDetector(scorers: []).dominantLanguage(of: "123 — 🙂", among: [.english, .russian]) == nil)
        #expect(LanguageDetector(scorers: []).dominantLanguage(of: "αβγ", among: [.english, .russian]) == nil)
    }

    /// A dictionary that knows the word outweighs a letter rule that forbids it.
    @Test func aKnownWordBeatsAnImpossiblePair() {
        let detector = LanguageDetector(scorers: [
            PhonotacticScorer(), FakeLexicon(known: [.english: ["fjord"]]),
        ])
        #expect(detector.plausibility(of: "fjord", as: .english) == .known)
    }

    @Test func oneImpossibleOpinionRulesTheWordOut() {
        let detector = LanguageDetector(scorers: [PhonotacticScorer(), FakeLexicon(known: [:])])
        #expect(detector.plausibility(of: "xnj", as: .english) == .impossible)
    }

    @Test func noScorersMeansUnknown() {
        #expect(LanguageDetector(scorers: []).plausibility(of: "word", as: .english) == .unknown)
    }
}
