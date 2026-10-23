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

    // A selection typed entirely in one layout is converted whole.

    @Test(arguments: [
        ("ghbdtn", "привет"),
        ("yfgbcfk", "написал"),
        ("Ghbdtn? rfr ltkf&", "Привет, как дела?"),
        ("b z yt pyf.", "и я не знаю"),
        ("ghbdtn,\n  vbh", "приветб\n  мир"),
        ("ghbdtn 2026", "привет 2026"),
        ("&", "?"),
    ])
    func usTypingIsConvertedWholeAndSwitchesToRussian(_ typed: String, _ meant: String) {
        #expect(corrector().correct(typed) == Correction(text: meant, targetLayoutID: russianWin))
    }

    @Test func russianTypingIsConvertedWholeAndSwitchesToUS() {
        #expect(corrector().correct("руддщ цщкдв") == Correction(text: "hello world", targetLayoutID: us))
    }

    /// A key that types a combining mark joins the letter before it into one character, which no
    /// single key types: the word is still known to come from its layout, that character alone
    /// included.
    @Test(arguments: [("ะ\u{0E49}รห", "this"), ("ะ\u{0E49}", "th")])
    func aWordWithACombiningMarkIsConverted(_ typed: String, _ meant: String) {
        let thai = LayoutCorrector(layouts: [.usQwerty, .thaiLike], detector: LanguageDetector(scorers: []))
        #expect(thai.correct(typed) == Correction(text: meant, targetLayoutID: us))
    }

    /// A key that types two characters (Arabic lam-alef) is retyped whole.
    @Test func aKeyThatTypesTwoCharactersIsConverted() {
        let ligature = KeyboardLayout(
            id: "test.ligature", language: Language(code: "ar"),
            output: [KeyStroke(keyCode: 0x0B, isShifted: false): "لا", KeyStroke(keyCode: 0x00, isShifted: false): "ل"])
        let withLigature = LayoutCorrector(layouts: [.usQwerty, ligature], detector: LanguageDetector(scorers: []))

        #expect(withLigature.correct("لال") == Correction(text: "ba", targetLayoutID: us))
    }

    /// "right" typed with Arabic – PC on: its G and H read better than lam-alef's B. Without
    /// evidence either way, the one key stays the reading, as before.
    @Test(arguments: [(["right"], "right"), ([], "ribt")] as [(Set<String>, String)])
    func textOneKeyAndSeveralKeysTypeGoesToTheBetterReading(_ known: Set<String>, _ meant: String) {
        let arabic = LayoutCorrector(
            layouts: [.usQwerty, .arabicPCLike],
            detector: LanguageDetector(scorers: [FakeLexicon(known: [.english: known])]))
        #expect(arabic.correct("قهلاف") == Correction(text: meant, targetLayoutID: us))
    }

    // Mixed text is decided word by word.

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

    /// The other layout lacks the Q key, so "q" converts into itself there: that is no fix, and
    /// the keyboard follows the last word that did change.
    @Test func aConversionThatChangesNothingDoesNotChooseTheLayout() {
        var output = KeyboardLayout.russianPC.output
        output[KeyStroke(keyCode: 0x0C, isShifted: false)] = nil
        let withoutQ = KeyboardLayout(id: "test.withoutQ", language: .russian, output: output)
        let detector = LanguageDetector(scorers: [FakeLexicon(known: [.english: ["hello"], .russian: ["q"]])])

        let fixed = LayoutCorrector(layouts: [.usQwerty, withoutQ], detector: detector).correct("руддщ q")

        #expect(fixed == Correction(text: "hello q", targetLayoutID: us))
    }

    /// For the log: which layouts a fix chose between, in the person's order.
    @Test func itNamesTheLayoutsItConvertsBetween() {
        let ids = LayoutCorrector(layouts: [.russianPC, .usQwerty], detector: LanguageDetector(scorers: [])).layoutIDs
        #expect(ids == [KeyboardLayout.russianPC.id, KeyboardLayout.usQwerty.id])
    }

    // Nothing to fix.

    /// "..." is typed by both layouts, on different keys, so neither owns it.
    @Test(arguments: ["", "   ", "123 — 🙂", "2 + 2 = 4", "..."])
    func textNoLayoutOwnsIsLeftAlone(_ text: String) {
        #expect(corrector().correct(text) == nil)
    }

    /// A key that types nothing in the other layout, like a dead key, leaves its text as it is.
    @Test func aKeyTheOtherLayoutLacksLeavesTheTextAlone() {
        var output = KeyboardLayout.russianPC.output
        output[KeyStroke(keyCode: 0x0C, isShifted: false)] = nil
        let withoutQ = KeyboardLayout(id: "test.withoutQ", language: .russian, output: output)
        let detector = LanguageDetector(scorers: [])
        #expect(LayoutCorrector(layouts: [.usQwerty, withoutQ], detector: detector).correct("q") == nil)
    }

    /// A German-like layout swaps Y and Z: "zoo" is a word either layout could have typed, so it
    /// says nothing about which one, and is left as it is rather than turned into "yoo".
    @Test func aWordEveryLayoutCouldHaveTypedIsLeftAlone() {
        var output = KeyboardLayout.usQwerty.output
        output[KeyStroke(keyCode: 0x10, isShifted: false)] = "z"
        output[KeyStroke(keyCode: 0x06, isShifted: false)] = "y"
        let qwertzLike = KeyboardLayout(id: "test.qwertz", language: Language(code: "de"), output: output)
        let detector = LanguageDetector(scorers: [PhonotacticScorer()])

        #expect(LayoutCorrector(layouts: [.usQwerty, qwertzLike], detector: detector).correct("zoo") == nil)
    }
}
