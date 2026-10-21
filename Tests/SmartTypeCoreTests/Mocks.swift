@testable import SmartTypeCore

/// Stands in for the macOS dictionary: knows exactly the words it was given.
struct FakeLexicon: WordScoring {
    let known: [Language: Set<String>]

    func score(_ word: String, as language: Language) -> Plausibility {
        known[language, default: []].contains(word.lowercased()) ? .known : .unknown
    }
}

extension KeyboardLayout {
    /// Thai Kedmanee's T, H, I and S keys: "ะ", the combining mai tho, "ร" and "ห".
    static let thaiLike = KeyboardLayout(
        id: "test.thai", language: Language(code: "th"),
        output: [
            KeyStroke(keyCode: 0x11, isShifted: false): "ะ", KeyStroke(keyCode: 0x04, isShifted: false): "\u{0E49}",
            KeyStroke(keyCode: 0x22, isShifted: false): "ร", KeyStroke(keyCode: 0x01, isShifted: false): "ห",
        ])
}

/// Says the same of every word, for an opinion no real scorer gives yet.
struct FixedOpinion: WordScoring {
    let plausibility: Plausibility

    func score(_ word: String, as language: Language) -> Plausibility {
        plausibility
    }
}
