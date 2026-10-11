@testable import SmartTypeCore

/// Stands in for the macOS dictionary: knows exactly the words it was given.
struct FakeLexicon: WordScorer {
    let known: [Language: Set<String>]

    func score(_ word: String, as language: Language) -> Plausibility {
        known[language, default: []].contains(word.lowercased()) ? .known : .unknown
    }
}
