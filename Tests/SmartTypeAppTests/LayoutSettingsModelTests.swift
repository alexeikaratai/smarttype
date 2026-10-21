import Foundation
import Testing

@testable import SmartTypeApp
@testable import SmartTypeCore

@Suite struct LayoutSettingsModelTests {
    private let us = InputSourceLayout(layout: .usQwerty, name: "U.S.")
    private let russian = InputSourceLayout(layout: .russianPC, name: "Russian – PC")
    private let hebrew = InputSourceLayout(
        layout: KeyboardLayout(id: "com.apple.keylayout.Hebrew", language: Language(code: "he"), output: [:]),
        name: "Hebrew")

    private func model(_ choices: LayoutChoices, enabled: [InputSourceLayout]) -> LayoutSettingsModel {
        LayoutSettingsModel(choices: choices, readEnabled: { enabled }, openURL: { _ in })
    }

    @Test func everyEnabledLayoutIsListedInMacOSOrderAndOn() {
        let layouts = model(.forTest(#function), enabled: [us, russian, hebrew])

        #expect(layouts.rows.map(\.name) == ["U.S.", "Russian – PC", "Hebrew"])
        #expect(layouts.rows.map(\.isOn) == [true, true, true])
        #expect(!layouts.needsASecondLayout)
    }

    @Test func aLayoutSwitchedOffIsRemembered() throws {
        let choices = LayoutChoices.forTest(#function)
        let layouts = model(choices, enabled: [us, russian, hebrew])

        layouts.set(hebrew.layout.id, isOn: false)

        #expect(choices.switchedOff == [hebrew.layout.id])
        #expect(try #require(layouts.rows.last).isOn == false)
    }

    /// A layout switched off can always come back, with only two others on too.
    @Test func aLayoutSwitchedOffComesBackOn() throws {
        let choices = LayoutChoices.forTest(#function)
        let layouts = model(choices, enabled: [us, russian, hebrew])
        layouts.set(hebrew.layout.id, isOn: false)
        #expect(layouts.canSwitch(try #require(layouts.rows.last)))

        layouts.set(hebrew.layout.id, isOn: true)

        #expect(choices.switchedOff.isEmpty)
        #expect(layouts.rows.map(\.isOn) == [true, true, true])
    }

    /// Two layouts at least, or there is nothing to fix between: the last two cannot go.
    @Test func theLastTwoLayoutsStayOn() throws {
        let choices = LayoutChoices.forTest(#function)
        let layouts = model(choices, enabled: [us, russian])
        let first = try #require(layouts.rows.first)

        layouts.set(first.id, isOn: false)

        #expect(!layouts.canSwitch(first))
        #expect(choices.switchedOff.isEmpty)
    }

    /// With one layout in macOS, the section says to add a second one.
    @Test func oneLayoutInMacOSNeedsASecond() {
        let layouts = model(.forTest(#function), enabled: [us])

        #expect(layouts.needsASecondLayout)
        #expect(!layouts.needsASecondSwitchedOn)
    }

    /// Switched off while three were on, then one removed in macOS: one is left on, so Fix
    /// Layout beeps, and the section says to switch the other back on.
    @Test func oneLayoutLeftOnNeedsASecondSwitchedOn() {
        let choices = LayoutChoices.forTest(#function)
        choices.switchedOff = [russian.layout.id]

        let layouts = model(choices, enabled: [us, russian])

        #expect(layouts.needsASecondSwitchedOn)
        #expect(!layouts.needsASecondLayout)
    }

    /// Layouts come from macOS: Add Layout… opens the Keyboard pane, where Input Sources has Edit…
    /// (the pane allows its `x-apple.systempreferences` link; read from its Info.plist).
    @Test func addingALayoutOpensKeyboardSettings() {
        var opened: [URL] = []
        let layouts = LayoutSettingsModel(
            choices: .forTest(#function), readEnabled: { [] }, openURL: { opened.append($0) })

        layouts.addLayout()

        #expect(opened.map(\.absoluteString) == ["x-apple.systempreferences:com.apple.Keyboard-Settings.extension"])
    }

    /// Back from System Settings with a layout just turned on there.
    @Test func refreshingReadsTheLayoutsAgain() {
        var enabled = [us]
        let layouts = LayoutSettingsModel(choices: .forTest(#function), readEnabled: { enabled }, openURL: { _ in })

        enabled.append(russian)
        layouts.refresh()

        #expect(layouts.rows.map(\.name) == ["U.S.", "Russian – PC"])
    }
}
