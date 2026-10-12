import AppKit
import Carbon.HIToolbox
import SmartTypeCore
import Testing

@testable import SmartTypeApp

@Suite struct KeyTests {
    /// The 47 character keys, labelled from the U.S. layout SmartTypeCore measured.
    @Test func everyCharacterKeyCanMakeAShortcut() {
        #expect(KeyStroke.ansiKeyCodes.allSatisfy { Key(code: $0).isSupported })
    }

    @Test(arguments: [
        (kVK_ANSI_L, "L", "l"), (kVK_ANSI_5, "5", "5"), (kVK_ANSI_Semicolon, ";", ";"), (kVK_ANSI_Grave, "`", "`"),
        (kVK_Space, "Space", " "), (kVK_Return, "↩", "\r"), (kVK_Delete, "⌫", "\u{8}"),
    ])
    func aKeyIsLabelledAsOnAUSKeyboard(_ code: Int, _ label: String, _ menu: String) {
        let key = Key(code: UInt16(code))
        #expect(key.label == label)
        #expect(key.menuKeyEquivalent == menu)
    }

    /// Menus take AppKit's private-use characters for the function keys and arrows.
    @Test(arguments: [
        (kVK_F1, "F1", NSF1FunctionKey), (kVK_F5, "F5", NSF5FunctionKey), (kVK_F20, "F20", NSF20FunctionKey),
        (kVK_RightArrow, "→", NSRightArrowFunctionKey), (kVK_PageDown, "⇟", NSPageDownFunctionKey),
    ])
    func functionKeysAndArrowsUseAppKitsCharacters(_ code: Int, _ label: String, _ character: Int) {
        let key = Key(code: UInt16(code))
        #expect(key.label == label)
        #expect(Array(key.menuKeyEquivalent.utf16) == [UInt16(character)])
    }

    /// Esc cancels a recording; modifiers and the keypad have no place in a shortcut.
    @Test(arguments: [kVK_Escape, kVK_Shift, kVK_Command, kVK_CapsLock, kVK_ANSI_Keypad5, kVK_Function])
    func someKeysCannotMakeAShortcut(_ code: Int) {
        #expect(!Key(code: UInt16(code)).isSupported)
    }
}
