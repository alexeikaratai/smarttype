import AppKit
import Carbon.HIToolbox
import Testing

@testable import SmartTypeApp

@Suite struct KeyComboTests {
    @Test func aComboReadsTheWayMacOSPrintsIt() {
        #expect(KeyCombo(key: .l, modifiers: [.control, .option, .shift]).displayString == "⌃⌥⇧L")
    }

    @Test func modifiersAreAlwaysInMacOSOrderWhateverOrderTheyWereGivenIn() {
        let all: Modifiers = [.command, .shift, .option, .control]
        #expect(all.symbols == "⌃⌥⇧⌘")
    }

    @Test func everyModifierReachesCarbonAndAppKit() {
        #expect(Modifiers.all.carbonFlags == UInt32(controlKey | optionKey | shiftKey | cmdKey))
        #expect(Modifiers.all.eventFlags == [.control, .option, .shift, .command])
    }

    @Test(arguments: [Modifiers.control, .option, .shift, .command])
    func eachModifierMapsToItsOwnFlagOnly(_ modifier: Modifiers) {
        #expect(modifier.symbols.count == 1)
        #expect(modifier.carbonFlags.nonzeroBitCount == 1)
        #expect(Modifiers(eventFlags: modifier.eventFlags) == modifier)
        #expect(Modifiers(carbonFlags: modifier.carbonFlags) == modifier)
    }

    /// Caps Lock and fn are not part of a shortcut. macOS's own shortcuts carry fn (0x20000) in
    /// Carbon's flags (measured: 106 of the 176 switched on).
    @Test func onlyTheFourModifiersCount() {
        #expect(Modifiers(eventFlags: [.control, .shift, .capsLock, .function]) == [.control, .shift])
        #expect(Modifiers(carbonFlags: UInt32(controlKey | optionKey) | 0x20000) == [.control, .option])
    }

    @Test func keyCodesAreThePhysicalKeysNotTheLetters() {
        #expect(Key.l.code == UInt16(kVK_ANSI_L))
        #expect(Key.t.code == UInt16(kVK_ANSI_T))
    }

    /// The person's shortcuts are kept in this form: a change would lose every one of them.
    @Test func theStoredFormIsFrozen() {
        let combo = KeyCombo(key: .l, modifiers: [.control, .option, .shift])

        #expect(combo.storage == ["keyCode": 37, "modifiers": 7])
        #expect(KeyCombo(storage: ["keyCode": 37, "modifiers": 7]) == combo)
    }

    /// What another version or a hand edit may leave behind reads as nothing, never as the
    /// wrong keys. A bare L (0) or ⇧L (4) would take the letter from every app.
    @Test(arguments: [
        ["keyCode": 37], ["modifiers": 3], ["keyCode": 999, "modifiers": 3], ["keyCode": kVK_Escape, "modifiers": 3],
        ["keyCode": 37, "modifiers": 16], ["keyCode": -1, "modifiers": 3], ["keyCode": 37, "modifiers": 0],
        ["keyCode": 37, "modifiers": 4], ["keyCode": 37, "modifiers": 8],
    ])
    func aStoredValueThatIsNoShortcutReadsAsNothing(_ storage: [String: Int]) {
        #expect(KeyCombo(storage: storage) == nil)
    }
}
