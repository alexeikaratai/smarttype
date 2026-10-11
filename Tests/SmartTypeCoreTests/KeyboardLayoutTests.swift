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

    @Test func everyKeyRoundTripsBetweenUSAndRussian() {
        let there = LayoutConverter(from: .usQwerty, to: .russianPC)
        let back = LayoutConverter(from: .russianPC, to: .usQwerty)
        for text in KeyboardLayout.usQwerty.output.values {
            #expect(back.convert(there.convert(text)) == text)
        }
        for text in KeyboardLayout.russianPC.output.values {
            #expect(there.convert(back.convert(text)) == text)
        }
    }

    /// Measured: macOS's Russian – PC types Latin "Ë" (U+00CB) for Shift+`, not Cyrillic "Ё".
    @Test func whatMacOSReallyTypesForShiftGraveIsUnderstood() {
        let shiftGrave = KeyStroke(keyCode: KeyStroke.ansiKeyCodes[0], shift: true)
        #expect(KeyboardLayout.russianPC.output[shiftGrave] == "\u{0401}")
        #expect(KeyboardLayout.russianPC.keyStrokesByText["\u{00CB}"] == shiftGrave)
    }

    @Test func layoutsCarryTheirMacOSInputSourceIDs() {
        #expect(KeyboardLayout.usQwerty.id == "com.apple.keylayout.US")
        #expect(KeyboardLayout.russianPC.id == "com.apple.keylayout.RussianWin")
    }
}
