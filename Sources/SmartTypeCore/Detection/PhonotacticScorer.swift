/// Scores a word by the letter sequences its language never uses: `.impossible` when it has
/// one, `.unknown` otherwise. Finding no forbidden pair is not evidence of a real word.
package struct PhonotacticScorer: WordScorer, Sendable {
    private let profiles: [Language: LanguageProfile]

    package init(profiles: [LanguageProfile] = [.english, .russian]) {
        self.profiles = Dictionary(uniqueKeysWithValues: profiles.map { ($0.language, $0) })
    }

    package func score(_ word: String, as language: Language) -> Plausibility {
        guard let profile = profiles[language] else { return .unknown }
        let letters = Array(word.lowercased())
        guard let first = letters.first else { return .unknown }
        if profile.impossibleStarts.contains(String(first))
            || (letters.count > 1 && profile.impossibleStarts.contains(String(letters[0...1])))
        {
            return .impossible
        }
        for index in letters.indices.dropLast()
        where profile.impossiblePairs.contains(String(letters[index...index + 1])) {
            return .impossible
        }
        return .unknown
    }
}
