import AppKit
import Carbon.HIToolbox
import Testing

@testable import SmartTypeApp

@Suite struct KeyPressTests {
    private func event(_ type: NSEvent.EventType, _ flags: NSEvent.ModifierFlags, characters: String = "")
        throws -> NSEvent
    {
        try #require(
            NSEvent.keyEvent(
                with: type, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: 0, context: nil,
                characters: characters, charactersIgnoringModifiers: characters, isARepeat: false,
                keyCode: UInt16(kVK_ANSI_L)))
    }

    /// The physical key, whatever the layout typed: with Russian – PC active, L types "д".
    @Test func aKeyGoingDownIsItsCodeAndModifiers() throws {
        let press = try #require(
            KeyPress(try event(.keyDown, [.control, .option, .shift, .capsLock], characters: "д")))

        #expect(press.kind == .keyDown)
        #expect(press.keyCode == UInt16(kVK_ANSI_L))
        #expect(press.modifiers == [.control, .option, .shift])
    }

    @Test func aModifierChangeShowsWhatIsHeld() throws {
        let press = try #require(KeyPress(try event(.flagsChanged, [.control, .command])))

        #expect(press.kind == .modifiersChanged)
        #expect(press.modifiers == [.control, .command])
    }

    @Test func aKeyGoingUpIsNoPress() throws {
        #expect(KeyPress(try event(.keyUp, [.control])) == nil)
    }
}
