import Foundation
import Testing

@testable import SmartTypeApp
@testable import SmartTypeCore

@Suite struct LayoutChoicesTests {
    private let us = InputSourceLayout(layout: .usQwerty, name: "U.S.")
    private let russian = InputSourceLayout(layout: .russianPC, name: "Russian – PC")
    private let hebrew = InputSourceLayout(
        layout: KeyboardLayout(id: "com.apple.keylayout.Hebrew", language: Language(code: "he"), output: [:]),
        name: "Hebrew")

    /// Until the person switches one off, Fix Layout works between every layout enabled in macOS.
    @Test func everyEnabledLayoutIsFixedBetween() {
        #expect(LayoutChoices.forTest(#function).switchedOn([us, russian]).map(\.name) == ["U.S.", "Russian – PC"])
    }

    /// What is kept is what the person switched off, so a layout enabled in macOS later joins.
    @Test func aSwitchedOffLayoutIsLeftOutAndANewOneJoins() {
        let choices = LayoutChoices.forTest(#function)
        choices.switchedOff = [russian.layout.id]

        #expect(choices.switchedOn([us, russian, hebrew]).map(\.name) == ["U.S.", "Hebrew"])
    }

    /// By default the layouts come from macOS, as the fix and the menu read them: read-only.
    @Test func theLayoutsEnabledInMacOSAreReadByDefault() throws {
        let enabled = InputSourceLayouts.read()
        let choices = LayoutChoices.forTest(#function)
        choices.switchedOff = [try #require(enabled.first).layout.id]

        #expect(choices.switchedOn().map(\.layout.id) == enabled.dropFirst().map(\.layout.id))
    }

    @Test func theChoiceIsRemembered() {
        let defaults = UserDefaults.forTest(#function, part: "layouts")
        LayoutChoices(defaults: defaults).switchedOff = [hebrew.layout.id]

        #expect(LayoutChoices(defaults: defaults).switchedOff == [hebrew.layout.id])
        #expect(defaults.stringArray(forKey: "com.smarttype.layouts.switchedOff") == [hebrew.layout.id])
    }
}
