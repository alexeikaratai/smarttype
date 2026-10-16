import AppKit
import Carbon.HIToolbox

/// The window Settings and the welcome window are built in: glass from macOS 26, sized to its
/// content, and closed on Esc and on ⌘W, since an agent app has no main menu to answer them.
final class SettingsWindow: NSWindow {
    /// Laid out before it is sized: only then does the size include the title bar the content
    /// sits below (32pt short otherwise; measured).
    static func make(title: String, content: NSView) -> SettingsWindow {
        let window = SettingsWindow(
            contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: true)
        window.title = title
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.contentView = surface(for: content, in: window)
        window.layoutIfNeeded()
        window.setContentSize(window.contentView?.fittingSize ?? .zero)
        window.center()
        return window
    }

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

    /// Liquid Glass from macOS 26, the whole window: clear itself, with the glass under the
    /// content and rounded as the window is (16pt on macOS 27, measured; the window's corner
    /// mask clips the glass either way, clear or not). Glass follows light and dark, where
    /// SmartDock's HUD material stayed dark and read as white text on grey (seen live). Before
    /// macOS 26, the standard background.
    private static func surface(for content: NSView, in window: NSWindow) -> NSView {
        guard #available(macOS 26, *) else { return content }
        window.isOpaque = false
        window.backgroundColor = .clear
        let glass = NSGlassEffectView()
        glass.cornerRadius = 16
        glass.contentView = content
        return glass
    }
}
