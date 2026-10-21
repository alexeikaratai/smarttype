import Testing

@testable import SmartTypeCore

/// Three layouts or more: which one a word came from, and which one it goes to.
@Suite struct LayoutCorrectorManyLayoutsTests {
    private let russianWin = KeyboardLayout.russianPC.id
    private let us = KeyboardLayout.usQwerty.id

    /// Russian – PC with the S key typing Ukrainian "і" instead of "ы", enough to tell them apart.
    private let ukrainianLike: KeyboardLayout = {
        var output = KeyboardLayout.russianPC.output
        output[KeyStroke(keyCode: 0x01, isShifted: false)] = "і"
        return KeyboardLayout(id: "test.ukrainian", language: Language(code: "uk"), output: output)
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

    /// "мир" could come from Russian – PC or the Ukrainian-like layout, and Russian knows it:
    /// a word reads as typed in the best of its layouts, so it stays even though "vbh" is known.
    @Test func aMixedWordReadsAsTypedInItsBestLayout() {
        let known: [Language: Set<String>] = [.russian: ["привет", "мир"], .english: ["vbh"]]
        let fixed = threeLayoutCorrector(knowing: known).correct("ghbdtn мир")
        #expect(fixed == Correction(text: "привет мир", targetLayoutID: russianWin))
    }

    // Layouts that type the same letters.

    /// Russian – PC and the Ukrainian-like layout type "руддщ" on the same keys, so either could
    /// have typed it, and both read "hello".
    @Test func aSelectionTwoLayoutsCouldHaveTypedIsStillConverted() {
        let fixed = threeLayoutCorrector(knowing: [:]).correct("руддщ цщкдв")
        #expect(fixed == Correction(text: "hello world", targetLayoutID: us))
    }

    @Test func aMixedWordTwoLayoutsCouldHaveTypedIsStillFixed() {
        let fixed = threeLayoutCorrector(knowing: [.russian: ["привет"], .english: ["hello"]]).correct("ghbdtn руддщ")
        #expect(fixed == Correction(text: "привет hello", targetLayoutID: us))
    }

    /// A Polish-like layout types U.S. letters on the same keys, so converting between the two
    /// changes nothing and is never the fix: Russian is.
    @Test func aConversionThatChangesNothingIsNeverTheFix() {
        let polishLike = KeyboardLayout(
            id: "test.polish", language: Language(code: "pl"), output: KeyboardLayout.usQwerty.output)
        let detector = LanguageDetector(scorers: [PhonotacticScorer()])

        let fixed = LayoutCorrector(layouts: [.usQwerty, polishLike, .russianPC], detector: detector).correct("ghbdtn")

        #expect(fixed == Correction(text: "привет", targetLayoutID: russianWin))
    }

    /// Equal readings go to the layout higher in the person's list: Russian – PC and the
    /// Ukrainian-like layout both read "ghbdtn" as "привет".
    @Test(arguments: [true, false])
    func aTieGoesToTheLayoutHigherInTheList(_ isRussianFirst: Bool) {
        let cyrillic = isRussianFirst ? [KeyboardLayout.russianPC, ukrainianLike] : [ukrainianLike, .russianPC]
        let detector = LanguageDetector(scorers: [PhonotacticScorer()])

        let fixed = LayoutCorrector(layouts: [.usQwerty] + cyrillic, detector: detector).correct("ghbdtn")

        #expect(fixed?.targetLayoutID == cyrillic[0].id)
    }

    /// Ukrainian – PC types no "/" (measured), and U.S. and Russian – PC type it on different keys:
    /// which of the two it came from is anyone's guess, as it is with only those two layouts on.
    @Test func punctuationTwoLayoutsTypeOnDifferentKeysIsLeftAlone() {
        var output = ukrainianLike.output
        output[KeyStroke(keyCode: 0x2A, isShifted: true)] = nil
        let withoutSlash = KeyboardLayout(id: "test.withoutSlash", language: Language(code: "uk"), output: output)
        let detector = LanguageDetector(scorers: [PhonotacticScorer()])

        #expect(
            LayoutCorrector(layouts: [.usQwerty, .russianPC, withoutSlash], detector: detector).correct("/") == nil)
    }
}
