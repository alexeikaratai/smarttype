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
}
