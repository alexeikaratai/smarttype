import Foundation
import Testing

@testable import SmartTypeApp
@testable import SmartTypeCore

@Suite struct LayoutChoicesTests {
    private let hebrew = KeyboardLayout(id: "com.apple.keylayout.Hebrew", language: Language(code: "he"), output: [:])

    /// Until the person switches one off, Fix Layout works between every layout enabled in macOS.
    @Test func everyEnabledLayoutIsFixedBetween() {
        let choices = LayoutChoices.forTest(#function)

        #expect(
            choices.fixedBetween([.usQwerty, .russianPC]).map(\.id) == [
                KeyboardLayout.usQwerty.id, KeyboardLayout.russianPC.id,
            ])
    }

    /// What is kept is what the person switched off, so a layout enabled in macOS later joins.
    @Test func aSwitchedOffLayoutIsLeftOutAndANewOneJoins() {
        let choices = LayoutChoices.forTest(#function)
        choices.switchedOff = [KeyboardLayout.russianPC.id]

        let fixed = choices.fixedBetween([.usQwerty, .russianPC, hebrew])

        #expect(fixed.map(\.id) == [KeyboardLayout.usQwerty.id, hebrew.id])
    }

    @Test func theChoiceIsRemembered() {
        let defaults = UserDefaults.forTest(#function, part: "layouts")
        LayoutChoices(defaults: defaults).switchedOff = [hebrew.id]

        #expect(LayoutChoices(defaults: defaults).switchedOff == [hebrew.id])
        #expect(defaults.stringArray(forKey: "com.smarttype.layouts.switchedOff") == [hebrew.id])
    }
}
