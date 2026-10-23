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

extension KeyboardLayout {
    /// Arabic – PC's R, I, G, H, T and B keys (measured): B types lam-alef, «لا», which G and H
    /// type one after the other.
    static let arabicPCLike = KeyboardLayout(
        id: "test.arabic", language: Language(code: "ar"),
        output: [
            KeyStroke(keyCode: 0x0F, isShifted: false): "ق", KeyStroke(keyCode: 0x22, isShifted: false): "ه",
            KeyStroke(keyCode: 0x05, isShifted: false): "ل", KeyStroke(keyCode: 0x04, isShifted: false): "ا",
            KeyStroke(keyCode: 0x11, isShifted: false): "ف", KeyStroke(keyCode: 0x0B, isShifted: false): "لا",
        ])
}

/// Says the same of every word, for an opinion no real scorer gives yet.
struct FixedOpinion: WordScoring {
    let plausibility: Plausibility

    func score(_ word: String, as language: Language) -> Plausibility {
        plausibility
    }
}
