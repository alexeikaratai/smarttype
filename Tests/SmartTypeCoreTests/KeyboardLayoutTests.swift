import Testing

@testable import SmartTypeCore

@Suite struct KeyboardLayoutTests {
    @Test(arguments: BuiltInLayouts().layouts)
    func everyKeyTypesSomethingWithAndWithoutShift(_ layout: KeyboardLayout) {
        #expect(layout.output.count == KeyStroke.ansiKeyCodes.count * 2)
        #expect(!layout.output.values.contains(""))
    }

    /// Two keys typing the same text would make the conversion back ambiguous.
    @Test(arguments: BuiltInLayouts().layouts)
    func noTwoKeysTypeTheSameText(_ layout: KeyboardLayout) {
        #expect(Set(layout.output.values).count == layout.output.count)
    }

    /// Every pair of built-in layouts, both ways, so a new layout is checked against the others
    /// without a test of its own.
    @Test func everyKeyRoundTripsBetweenEveryTwoLayouts() {
        let layouts = BuiltInLayouts().layouts
        for from in layouts {
            for to in layouts where to.id != from.id {
                let there = LayoutConverter(from: from, to: to)
                let back = LayoutConverter(from: to, to: from)
                for text in from.output.values {
                    #expect(back.convert(there.convert(text)) == text, "\(from.id) → \(to.id): \(text)")
                }
            }
        }
    }

    /// Measured: macOS's Russian – PC types Latin "Ë" (U+00CB) for Shift+`, not Cyrillic "Ё".
    @Test func whatMacOSReallyTypesForShiftGraveIsUnderstood() {
        let shiftGrave = KeyStroke(keyCode: KeyStroke.ansiKeyCodes[0], isShifted: true)
        #expect(KeyboardLayout.russianPC.output[shiftGrave] == "\u{0401}")
        #expect(KeyboardLayout.russianPC.keyStrokesByText["\u{00CB}"] == shiftGrave)
    }

    @Test func layoutsCarryTheirMacOSInputSourceIDs() {
        #expect(KeyboardLayout.usQwerty.id == "com.apple.keylayout.US")
        #expect(KeyboardLayout.russianPC.id == "com.apple.keylayout.RussianWin")
    }

    // Read from macOS.

    /// U.S. as `UCKeyTranslate` reports it, one text per key, with `change` applied.
    private func measured(_ change: (inout [String], inout [String]) -> Void) -> KeyboardLayout {
        func typed(shifted: Bool) -> [String] {
            KeyStroke.ansiKeyCodes.map {
                KeyboardLayout.usQwerty.output[KeyStroke(keyCode: $0, isShifted: shifted)] ?? ""
            }
        }
        var unshifted = typed(shifted: false)
        var shifted = typed(shifted: true)
        change(&unshifted, &shifted)
        return KeyboardLayout(
            id: "test.measured", language: .english, measuredUnshifted: unshifted, measuredShifted: shifted)
    }

    /// A dead key types nothing on its own (measured: 2 keys in German, 21 in Hebrew), and a
    /// control character is nothing a person typed: both are left out.
    @Test func aKeyThatTypesNothingIsLeftOut() {
        let layout = measured { unshifted, shifted in
            unshifted[12] = ""
            shifted[12] = "\u{10}"
        }

        #expect(layout.output[KeyStroke(keyCode: KeyStroke.ansiKeyCodes[12], isShifted: false)] == nil)
        #expect(layout.output[KeyStroke(keyCode: KeyStroke.ansiKeyCodes[12], isShifted: true)] == nil)
        #expect(layout.output.count == KeyStroke.ansiKeyCodes.count * 2 - 2)
    }

    /// Each row is read against its own keys: a short unshifted row leaves the shifted keys where
    /// they are.
    @Test func aShortRowNeverMovesTheOtherOne() {
        let layout = measured { unshifted, _ in unshifted.removeLast() }

        #expect(layout.output[KeyStroke(keyCode: KeyStroke.ansiKeyCodes[0], isShifted: true)] == "~")
        #expect(layout.output[KeyStroke(keyCode: KeyStroke.ansiKeyCodes[46], isShifted: false)] == nil)
    }

    /// Two keys typing the same text (measured: Armenian, Hebrew, Arabic) would leave converting
    /// back to a guess, so the first key keeps it, unshifted before shifted.
    @Test func aTextTwoKeysTypeKeepsTheFirstKey() {
        let layout = measured { _, shifted in shifted[1] = "a" }

        #expect(layout.keyStrokesByText["a"] == KeyStroke(keyCode: KeyStroke.ansiKeyCodes[26], isShifted: false))
        #expect(layout.output[KeyStroke(keyCode: KeyStroke.ansiKeyCodes[1], isShifted: true)] == nil)
    }
}
