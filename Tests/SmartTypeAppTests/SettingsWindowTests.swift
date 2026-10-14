import AppKit
import Carbon.HIToolbox
import Testing

@testable import SmartTypeApp

/// How the Settings window looks and closes.
@Suite struct SettingsWindowTests {
    init() {
        _ = NSApplication.shared
    }

    /// SwiftUI lays the content out below the title bar, so the window must be taller than the
    /// content by the bar. Sized before layout, it came out 32pt short and clipped the bottom.
    @Test func theWindowFitsItsContentBelowTheTitleBar() throws {
        let controller = SettingsWindowController.forTest(#function)
        controller.show()
        let window = try #require(controller.window)
        let content = try #require(window.contentView)

        content.layoutSubtreeIfNeeded()

        #expect(window.frame.size == content.fittingSize)
    }

    /// From macOS 26 the whole window is Liquid Glass: clear itself, with the glass under the
    /// content, so the desktop shows through and the glass follows light and dark.
    @Test func theWindowIsGlassFromMacOS26() throws {
        guard #available(macOS 26, *) else { return }
        let controller = SettingsWindowController.forTest(#function)
        controller.show()
        let window = try #require(controller.window)

        #expect(window.contentView is NSGlassEffectView)
        #expect(!window.isOpaque)
        #expect(window.backgroundColor == .clear)
    }

    @Test func escapeClosesTheWindow() throws {
        let controller = SettingsWindowController.forTest(#function)
        controller.show()

        try #require(controller.window).cancelOperation(nil)

        #expect(controller.window == nil)
    }

    /// An agent app has no main menu, so nothing else answers ⌘W. With Russian – PC active
    /// the key types "ц": the key closes the window, not the letter.
    @Test func commandWClosesTheWindowInAnyLayout() throws {
        let controller = SettingsWindowController.forTest(#function)
        controller.show()
        let window = try #require(controller.window)
        let commandW = try #require(
            NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0,
                windowNumber: window.windowNumber, context: nil, characters: "ц", charactersIgnoringModifiers: "ц",
                isARepeat: false, keyCode: UInt16(kVK_ANSI_W)))

        #expect(window.performKeyEquivalent(with: commandW))
        #expect(controller.window == nil)
    }
}
