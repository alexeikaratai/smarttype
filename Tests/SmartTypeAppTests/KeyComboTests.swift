import AppKit
import Carbon.HIToolbox
import Foundation
import Testing

@testable import SmartTypeApp

@Suite struct KeyComboTests {
    @Test func aComboReadsTheWayMacOSPrintsIt() {
        #expect(KeyCombo(key: .l, modifiers: [.control, .option]).displayString == "⌃⌥L")
    }

    @Test func modifiersAreAlwaysInMacOSOrderWhateverOrderTheyWereGivenIn() {
        let all: Modifiers = [.command, .shift, .option, .control]
        #expect(all.symbols == "⌃⌥⇧⌘")
    }

    @Test func everyModifierReachesCarbonAndAppKit() {
        let all: Modifiers = [.control, .option, .shift, .command]
        #expect(all.carbonFlags == UInt32(controlKey | optionKey | shiftKey | cmdKey))
        #expect(all.eventFlags == [.control, .option, .shift, .command])
    }

    @Test(arguments: [Modifiers.control, .option, .shift, .command])
    func eachModifierMapsToItsOwnFlagOnly(_ modifier: Modifiers) {
        #expect(modifier.symbols.count == 1)
        #expect(modifier.carbonFlags.nonzeroBitCount == 1)
    }

    @Test func keyCodesAreThePhysicalKeysNotTheLetters() {
        #expect(Key.l.code == UInt16(kVK_ANSI_L))
        #expect(Key.t.code == UInt16(kVK_ANSI_T))
    }

    @Test func aComboSurvivesEncoding() throws {
        let combo = KeyCombo(key: .t, modifiers: [.control, .option])
        let decoded = try JSONDecoder().decode(KeyCombo.self, from: JSONEncoder().encode(combo))
        #expect(decoded == combo)
    }
}
