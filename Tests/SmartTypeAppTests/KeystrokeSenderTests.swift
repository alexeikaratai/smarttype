import Carbon.HIToolbox
import CoreGraphics
import Testing

@testable import SmartTypeApp

@Suite struct KeystrokeSenderTests {
    /// What reached the event tap, one line per event: "down 8 ⌘".
    private final class Tap {
        private(set) var events: [String] = []

        func record(_ event: CGEvent) {
            let key = event.getIntegerValueField(.keyboardEventKeycode)
            let command = event.flags.contains(.maskCommand) ? " ⌘" : ""
            events.append("\(event.type == .keyDown ? "down" : "up") \(key)\(command)")
        }
    }

    @Test func aCopyIsCommandCPressedAndReleased() async {
        let tap = Tap()
        let keystrokes = KeystrokeSender(currentModifiers: { [] }, post: { tap.record($0) }, pause: { _ in })

        let pressed = await keystrokes.press(.copy)

        #expect(pressed)
        #expect(tap.events == ["down \(kVK_ANSI_C) ⌘", "up \(kVK_ANSI_C) ⌘"])
    }

    /// The hotkey fires with its modifiers still held, and ⌘C sent then would arrive as ⌃⌥⇧⌘C.
    @Test func theKeysWaitUntilTheHotKeysModifiersAreReleased() async {
        var held: [CGEventFlags] = [[.maskControl, .maskAlternate], [.maskAlternate]]
        var pauses = 0
        let tap = Tap()
        let keystrokes = KeystrokeSender(
            currentModifiers: { held.isEmpty ? [] : held.removeFirst() },
            post: { tap.record($0) },
            pause: { _ in pauses += 1 })

        let pressed = await keystrokes.press(.paste)

        #expect(pressed)
        #expect(pauses == 2)
        #expect(tap.events == ["down \(kVK_ANSI_V) ⌘", "up \(kVK_ANSI_V) ⌘"])
    }

    /// At most a second, in 10 ms steps: then nothing is pressed at all.
    @Test func modifiersHeldForASecondCancelThePress() async {
        var pauses = 0
        let tap = Tap()
        let keystrokes = KeystrokeSender(
            currentModifiers: { .maskControl }, post: { tap.record($0) }, pause: { _ in pauses += 1 })

        let pressed = await keystrokes.press(.copy)

        #expect(!pressed)
        #expect(pauses == 100)
        #expect(tap.events.isEmpty)
    }

    @Test func capsLockIsNotAKeyToWaitFor() async {
        let keystrokes = KeystrokeSender(currentModifiers: { .maskAlphaShift }, post: { _ in }, pause: { _ in })

        let pressed = await keystrokes.press(.copy)

        #expect(pressed)
    }
}
