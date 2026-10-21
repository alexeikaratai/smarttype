import Testing

@testable import SmartTypeCore

@Suite struct LayoutConverterTests {
    private let toRussian = LayoutConverter(from: .usQwerty, to: .russianPC)
    private let toEnglish = LayoutConverter(from: .russianPC, to: .usQwerty)

    @Test(arguments: [
        ("ghbdtn", "привет"),
        ("yfgbcfk", "написал"),
        ("Ghbdtn? rfr ltkf&", "Привет, как дела?"),
        ("@$^&,", "\";:?б"),
        ("`", "ё"),
        ("~", "\u{0401}"),
        ("vj;yj", "можно"),
        ("[jhjij", "хорошо"),
    ])
    func usTypingBecomesRussian(_ typed: String, _ meant: String) {
        #expect(toRussian.convert(typed) == meant)
    }

    @Test(arguments: [
        ("руддщ", "hello"),
        ("цщкдв", "world"),
        ("вщтэе", "don't"),
        ("\u{00CB}", "~"),
        ("\u{0401}", "~"),
    ])
    func russianTypingBecomesUS(_ typed: String, _ meant: String) {
        #expect(toEnglish.convert(typed) == meant)
    }

    @Test func charactersNoKeyTypesPassThrough() {
        #expect(toRussian.convert("123 — 🙂\n\t") == "123 — 🙂\n\t")
    }

    @Test func aKeyThatTypesSeveralCharactersIsMatchedWhole() {
        let ligature = KeyboardLayout(
            id: "test.ligature", language: .english,
            output: [KeyStroke(keyCode: 0x0B, isShifted: false): "لا", KeyStroke(keyCode: 0x00, isShifted: false): "ل"])
        let plain = KeyboardLayout(
            id: "test.plain", language: .english,
            output: [KeyStroke(keyCode: 0x0B, isShifted: false): "b", KeyStroke(keyCode: 0x00, isShifted: false): "a"])

        #expect(LayoutConverter(from: ligature, to: plain).convert("لال") == "ba")
    }

    /// A key that types a combining mark, as Thai's mai tho does, joins the letter before it into
    /// one character, which no single key types: each is still retyped on its own key.
    @Test func aCombiningMarkIsRetypedOnItsOwnKey() {
        #expect(LayoutConverter(from: .thaiLike, to: .usQwerty).convert("ะ\u{0E49}รห") == "this")
    }
}
