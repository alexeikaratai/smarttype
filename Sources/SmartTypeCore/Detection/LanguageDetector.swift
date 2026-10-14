/// The detection module: how plausible a word is in a language. Opinions come from injected
/// scorers (letter rules, the macOS dictionary, later an LLM judge for ties), so the detector
/// runs wherever its scorers can run. Which language a translation comes from is
/// `SourceLanguage`'s job, in SmartTypeEngines.
package struct LanguageDetector {
    private let scorers: [any WordScoring]

    package init(scorers: [any WordScoring]) {
        self.scorers = scorers
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
