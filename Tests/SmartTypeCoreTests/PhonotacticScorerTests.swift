import Testing

@testable import SmartTypeCore

@Suite struct PhonotacticScorerTests {
    private let scorer = PhonotacticScorer()

    /// Russian words typed with the U.S. layout active.
    @Test(arguments: ["yf", "yfgbcfk", "rfr", "jnrfp", "xnj", "vj;yj", "gjkt"])
    func russianTypedInUSLooksImpossibleInEnglish(_ word: String) {
        #expect(scorer.score(word.filter(\.isLetter), as: .english) == .impossible)
    }

    /// English words typed with the Russian layout active.
    @Test(arguments: ["цщкдв", "ыщ", "ьн", "ырщц", "ьщву"])
    func englishTypedInRussianLooksImpossibleInRussian(_ word: String) {
        #expect(scorer.score(word, as: .russian) == .impossible)
    }

    /// One word per Russian rule: ь, ъ and ы after a vowel; ь after й; ъ before a consonant; ж,
    /// ш, ч, щ before ы, я, ю; щ before a consonant or ъ.
    @Test(arguments: ["тоь", "заъ", "моы", "мойь", "съм", "жыр", "чяс", "ищт", "ищъ"])
    func eachRussianRuleRulesAWordOut(_ word: String) {
        #expect(scorer.score(word, as: .russian) == .impossible)
    }

    @Test(arguments: [
        "hello", "world", "keyboard", "layout", "translation", "select", "if", "of", "the", "and", "quickly", "rhythm",
        "jazz", "subject", "adjust",
    ])
    func everydayEnglishIsNeverRuledOut(_ word: String) {
        #expect(scorer.score(word, as: .english) != .impossible)
    }

    @Test(arguments: [
        "привет", "раскладка", "объявление", "подъезд", "семья", "счастье", "щука", "помощь", "мощный", "ещё",
        "жизнь", "шина", "чашка", "чудо", "брошюра", "жюри", "парашют", "район", "поэт", "аэропорт", "объём",
    ])
    func everydayRussianIsNeverRuledOut(_ word: String) {
        #expect(scorer.score(word, as: .russian) != .impossible)
    }

    /// "z" and "я" are whole words in mixed text, and a one-letter word has no pair to look at.
    @Test(arguments: [
        ("a", Language.english, Plausibility.unknown), ("я", .russian, .unknown), ("ы", .russian, .impossible),
    ])
    func aOneLetterWordIsReadByItsStart(_ word: String, _ language: Language, _ expected: Plausibility) {
        #expect(scorer.score(word, as: language) == expected)
    }

    @Test func anEmptyWordIsUnknown() {
        #expect(scorer.score("", as: .english) == .unknown)
    }

    @Test func aLanguageWithoutAProfileIsUnknown() {
        #expect(scorer.score("xyz", as: Language(code: "de")) == .unknown)
    }
}
