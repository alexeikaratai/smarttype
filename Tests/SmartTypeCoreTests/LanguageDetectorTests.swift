import Testing

@testable import SmartTypeCore

@Suite struct LanguageDetectorTests {
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

    /// Short of a known word or an impossible one, the highest opinion wins.
    @Test func theHighestOtherOpinionWins() {
        let detector = LanguageDetector(scorers: [PhonotacticScorer(), FixedOpinion(plausibility: .likely)])
        #expect(detector.plausibility(of: "word", as: .english) == .likely)
    }

    @Test func noScorersMeansUnknown() {
        #expect(LanguageDetector(scorers: []).plausibility(of: "word", as: .english) == .unknown)
    }
}
