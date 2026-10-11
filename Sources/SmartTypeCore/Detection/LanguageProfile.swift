/// Letter sequences a language does not use: the cheapest sign that a word was typed in the
/// wrong layout. Data only; `PhonotacticScorer` applies it.
package struct LanguageProfile: Sendable {
    package let language: Language
    /// Two-letter sequences no word of the language contains.
    package let impossiblePairs: Set<String>
    /// Beginnings, of one or two letters, no word of the language has.
    package let impossibleStarts: Set<String>

    /// Each list entry holds several sequences separated by spaces, so data files stay readable.
    package init(language: Language, impossiblePairs: [String], impossibleStarts: [String]) {
        self.language = language
        self.impossiblePairs = Set(impossiblePairs.flatMap { $0.split(separator: " ").map(String.init) })
        self.impossibleStarts = Set(impossibleStarts.flatMap { $0.split(separator: " ").map(String.init) })
    }
}
