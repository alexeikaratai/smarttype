import Carbon.HIToolbox
import CoreGraphics
import Testing

@testable import SmartTypeApp

@Suite struct KeystrokeSenderTests {
    /// The ANSI keys, as in U.S. and Russian – PC, so no test depends on the layout in use.
    private func sender(
        _ tap: EventTapRecorder, held: @escaping () -> CGEventFlags = { [] },
        pause: @escaping (Duration) async -> Void = { _ in }
    ) -> KeystrokeSender {
        KeystrokeSender(currentModifiers: held, keyCode: \.ansiKeyCode, post: { tap.record($0) }, pause: pause)
    }

    @Test func aCopyIsCommandCPressedAndReleased() async {
        let tap = EventTapRecorder()

        let pressed = await sender(tap).press(.copy)

        #expect(pressed)
        #expect(tap.events == ["down \(kVK_ANSI_C) ⌘", "up \(kVK_ANSI_C) ⌘"])
    }

    /// The hotkey fires with its modifiers still held, and ⌘C sent then would arrive as ⌃⌥⇧⌘C.
    @Test func theKeysWaitUntilTheHotKeysModifiersAreReleased() async {
        var held: [CGEventFlags] = [[.maskControl, .maskAlternate], [.maskAlternate]]
        var pauses = 0
        let tap = EventTapRecorder()
        let keystrokes = sender(tap, held: { held.isEmpty ? [] : held.removeFirst() }, pause: { _ in pauses += 1 })

        let pressed = await keystrokes.press(.paste)

        #expect(pressed)
        #expect(pauses == 2)
        #expect(tap.events == ["down \(kVK_ANSI_V) ⌘", "up \(kVK_ANSI_V) ⌘"])
    }

    /// At most a second, in 10 ms steps: then nothing is pressed at all.
    @Test func modifiersHeldForASecondCancelThePress() async {
        var pauses = 0
        let tap = EventTapRecorder()

        let pressed = await sender(tap, held: { .maskControl }, pause: { _ in pauses += 1 }).press(.copy)

        #expect(!pressed)
        #expect(pauses == 100)
        #expect(tap.events.isEmpty)
    }

    /// Each of ⌃⌥⇧⌘ held alone holds the press: ⇧ is in the default shortcuts, and ⇧⌘V is
    /// another command in many apps.
    @Test(arguments: [CGEventFlags.maskControl, .maskAlternate, .maskShift, .maskCommand])
    func everyModifierHeldIsWaitedFor(_ modifier: CGEventFlags) async {
        let tap = EventTapRecorder()

        let pressed = await sender(tap, held: { modifier }).press(.copy)

        #expect(!pressed)
        #expect(tap.events.isEmpty)
    }

    @Test func capsLockIsNotAKeyToWaitFor() async {
        let pressed = await sender(EventTapRecorder(), held: { .maskAlphaShift }).press(.copy)

        #expect(pressed)
    }

    /// Apps read a ⌘ shortcut by what its key types: in Dvorak the C key types ⌘J, so ⌘C goes
    /// on the key that types "c" there (I), and ⌘V on the one that types "v" (the period).
    @Test func theKeyComesFromTheLayoutInUse() async {
        let tap = EventTapRecorder()
        let dvorak = KeystrokeSender(
            currentModifiers: { [] }, keyCode: { $0 == .copy ? CGKeyCode(kVK_ANSI_I) : CGKeyCode(kVK_ANSI_Period) },
            post: { tap.record($0) }, pause: { _ in })

        _ = await dvorak.press(.copy)
        _ = await dvorak.press(.paste)

        #expect(
            tap.events == [
                "down \(kVK_ANSI_I) ⌘", "up \(kVK_ANSI_I) ⌘", "down \(kVK_ANSI_Period) ⌘", "up \(kVK_ANSI_Period) ⌘",
            ])
    }
}
