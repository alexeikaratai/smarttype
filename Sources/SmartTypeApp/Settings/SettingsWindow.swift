import AppKit
import Carbon.HIToolbox

/// Closes on Esc and on ⌘W. An agent app has no main menu, so nothing else answers them.
final class SettingsWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) {
        performClose(sender)
    }

    /// Matches the key, not the letter: with Russian – PC active, ⌘W types "ц".
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        guard modifiers == .command, Int(event.keyCode) == kVK_ANSI_W else {
            return super.performKeyEquivalent(with: event)
        }
        performClose(nil)
        return true
    }
}
