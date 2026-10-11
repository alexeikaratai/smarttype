import Testing

@testable import SmartTypeCore

@Suite struct LayoutCorrectorTests {
    private let russianWin = KeyboardLayout.russianPC.id
    private let us = KeyboardLayout.usQwerty.id

    private func corrector(knowing known: [Language: Set<String>] = [:]) -> LayoutCorrector {
        LayoutCorrector(
            layouts: BuiltInLayouts().layouts,
            detector: LanguageDetector(scorers: [PhonotacticScorer(), FakeLexicon(known: known)]))
    }

    // MARK: - A selection typed entirely in one layout is converted whole

    @Test(arguments: [
        ("ghbdtn", "привет"),
        ("yfgbcfk", "написал"),
        ("Ghbdtn? rfr ltkf&", "Привет, как дела?"),
        ("b z yt pyf.", "и я не знаю"),
        ("ghbdtn,\n  vbh", "приветб\n  мир"),
    ])
    func usTypingIsConvertedWholeAndSwitchesToRussian(_ typed: String, _ meant: String) {
        #expect(corrector().correct(typed) == Correction(text: meant, targetLayoutID: russianWin))
    }

    @Test func russianTypingIsConvertedWholeAndSwitchesToUS() {
        #expect(corrector().correct("руддщ цщкдв") == Correction(text: "hello world", targetLayoutID: us))
    }

    // MARK: - Mixed text is decided word by word

    @Test func onlyTheWordThatReadsBetterConvertedIsFixed() {
        let fixed = corrector(knowing: [.russian: ["привет"]]).correct("Привет, ghbdtn")
        #expect(fixed == Correction(text: "Привет, привет", targetLayoutID: russianWin))
    }

    @Test func theLayoutToSwitchToIsTheOneOfTheLastFixedWord() {
        let fixed = corrector(knowing: [.english: ["hello"], .russian: ["мир"]]).correct("руддщ vbh")
        // Mixed: "руддщ" reads as "hello", "vbh" as "мир" — the caret ends after "мир".
        #expect(fixed == Correction(text: "hello мир", targetLayoutID: russianWin))
    }

    /// Without evidence either way, a word is left as typed.
    @Test func aTieKeepsTheOriginal() {
        #expect(corrector().correct("Привет, ghbdtn") == nil)
    }

    // MARK: - More than two layouts

    /// Russian – PC with the S key typing Ukrainian "і" instead of "ы", enough to tell them apart.
    private let ukrainianLike: KeyboardLayout = {
        var output = KeyboardLayout.russianPC.output
        output[KeyStroke(keyCode: 0x01, shift: false)] = "і"
        return KeyboardLayout(id: "test.ukrainian", language: Language(code: "uk", script: .cyrillic), output: output)
    }()

    private func threeLayoutCorrector(knowing known: [Language: Set<String>]) -> LayoutCorrector {
        LayoutCorrector(
            layouts: BuiltInLayouts().layouts + [ukrainianLike],
            detector: LanguageDetector(scorers: [PhonotacticScorer(), FakeLexicon(known: known)]))
    }

    @Test func aWholeSelectionGoesToTheLayoutWhoseLanguageReadsBest() {
        // "vsh" reads "мыр" in Russian – PC and "мір" in the Ukrainian-like layout.
        let fixed = threeLayoutCorrector(knowing: [ukrainianLike.language: ["мір"]]).correct("vsh")
        #expect(fixed == Correction(text: "мір", targetLayoutID: ukrainianLike.id))
    }

    @Test func eachMixedWordGoesToTheLayoutWhoseLanguageReadsBest() {
        // "ырщц" reads "show" or "ірщц"; "vsh" reads "мыр" or "мір".
        let known: [Language: Set<String>] = [.english: ["show"], ukrainianLike.language: ["мір"]]
        let fixed = threeLayoutCorrector(knowing: known).correct("ырщц vsh")
        #expect(fixed == Correction(text: "show мір", targetLayoutID: ukrainianLike.id))
    }

    // MARK: - Nothing to fix

    /// "..." is typed by both layouts, on different keys, so neither owns it.
    @Test(arguments: ["", "   ", "123 — 🙂", "2 + 2 = 4", "..."])
    func textNoLayoutOwnsIsLeftAlone(_ text: String) {
        #expect(corrector().correct(text) == nil)
    }

    /// A key that types nothing in the other layout, like a dead key, leaves its text as it is.
    @Test func aKeyTheOtherLayoutLacksLeavesTheTextAlone() {
        var output = KeyboardLayout.russianPC.output
        output[KeyStroke(keyCode: 0x0C, shift: false)] = nil
        let withoutQ = KeyboardLayout(id: "test.withoutQ", language: .russian, output: output)
        let corrector = LayoutCorrector(layouts: [.usQwerty, withoutQ], detector: LanguageDetector(scorers: []))
        #expect(corrector.correct("q") == nil)
    }
}
