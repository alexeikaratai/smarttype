/// The detection module: which language a text is in, and how plausible a word is in a
/// language. Opinions come from injected scorers (letter rules, the macOS dictionary, later an
/// LLM judge for ties), so the detector runs wherever its scorers can run.
package struct LanguageDetector {
    private let scorers: [any WordScorer]

    package init(scorers: [any WordScorer]) {
        self.scorers = scorers
    }

    /// The candidate whose script has the most letters in `text`; on a tie, the earlier one.
    package func dominantLanguage(of text: some StringProtocol, among candidates: [Language]) -> Language? {
        var letters: [Script: Int] = [:]
        for character in text {
            if let script = Script(of: character) {
                letters[script, default: 0] += 1
            }
        }
        return
            candidates
            .filter { letters[$0.script, default: 0] > 0 }
            .max { letters[$0.script, default: 0] < letters[$1.script, default: 0] }
    }

    /// A dictionary that knows the word outweighs a rule that forbids it. Short of that, one
    /// impossible pair rules the word out, and among the remaining opinions the highest wins.
    package func plausibility(of word: String, as language: Language) -> Plausibility {
        let opinions = scorers.map { $0.score(word, as: language) }
        if opinions.contains(.known) {
            return .known
        }
        if opinions.contains(.impossible) {
            return .impossible
        }
        return opinions.max() ?? .unknown
    }
}
