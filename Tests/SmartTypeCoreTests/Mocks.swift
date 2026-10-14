@testable import SmartTypeCore

/// Stands in for the macOS dictionary: knows exactly the words it was given.
struct FakeLexicon: WordScoring {
    let known: [Language: Set<String>]

    func score(_ word: String, as language: Language) -> Plausibility {
        known[language, default: []].contains(word.lowercased()) ? .known : .unknown
    }
}

/// Says the same of every word, for an opinion no real scorer gives yet.
struct FixedOpinion: WordScoring {
    let plausibility: Plausibility

    func score(_ word: String, as language: Language) -> Plausibility {
        plausibility
    }
}
