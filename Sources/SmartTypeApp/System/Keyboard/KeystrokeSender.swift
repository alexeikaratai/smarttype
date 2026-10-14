import Carbon.HIToolbox
import CoreGraphics

/// Presses ⌘C and ⌘V in the frontmost app.
///
/// The hotkey fires while its modifiers (⌃⌥⇧ by default) are still held, and a ⌘C sent at that
/// moment arrives as ⌃⌥⇧⌘C and does nothing. So a press first waits for the physical modifiers
/// to come up: explicit flags alone are not enough, as Espanso and Sorla measured too.
struct KeystrokeSender {
    enum Shortcut {
        case copy
        case paste

        /// The physical key, which ⌘ turns into Copy or Paste in any keyboard layout.
        var keyCode: CGKeyCode {
            switch self {
            case .copy: CGKeyCode(kVK_ANSI_C)
            case .paste: CGKeyCode(kVK_ANSI_V)
            }
        }
    }

    private let currentModifiers: () -> CGEventFlags
    private let post: (CGEvent) -> Void
    private let pause: (Duration) async -> Void

    init(
        currentModifiers: @escaping () -> CGEventFlags = { CGEventSource.flagsState(.hidSystemState) },
        post: @escaping (CGEvent) -> Void = { $0.post(tap: .cgSessionEventTap) },
        pause: @escaping (Duration) async -> Void = { try? await Task.sleep(for: $0) }
    ) {
        self.currentModifiers = currentModifiers
        self.post = post
        self.pause = pause
    }

    /// `false` when the modifiers were still held after a second, and nothing was pressed.
    func press(_ shortcut: Shortcut) async -> Bool {
        guard await waitForModifiersReleased() else { return false }
        return send(shortcut)
    }

    /// Checks every 10 ms, for at most a second; `false` when they are still held then. Caps Lock
    /// is a state, not a key held down.
    func waitForModifiersReleased() async -> Bool {
        let held: CGEventFlags = [.maskControl, .maskAlternate, .maskShift, .maskCommand]
        for _ in 0..<100 {
            if currentModifiers().isDisjoint(with: held) {
                return true
            }
            await pause(.milliseconds(10))
        }
        return false
    }

    /// Presses at once, for a caller that has waited for the modifiers itself.
    func send(_ shortcut: Shortcut) -> Bool {
        for isDown in [true, false] {
            guard let event = CGEvent(keyboardEventSource: nil, virtualKey: shortcut.keyCode, keyDown: isDown) else {
                return false
            }
            event.flags = .maskCommand
            post(event)
        }
        return true
    }
}
