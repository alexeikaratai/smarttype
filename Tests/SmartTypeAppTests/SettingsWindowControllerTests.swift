import AppKit
import Carbon.HIToolbox
import Testing

@testable import SmartTypeApp

@Suite struct SettingsWindowControllerTests {
    init() {
        _ = NSApplication.shared
    }

    /// Never brings anything forward: a test must not put a window on the screen.
    private func settings(
        _ macOS: PermissionRecorder = PermissionRecorder(),
        present: @escaping (NSWindow) -> Void = { _ in }
    ) -> SettingsWindowController {
        SettingsWindowController(
            refusedHotKeys: [], permission: macOS.permission(), openURL: { _ in }, present: present)
    }

    @Test func showingTwiceBringsTheSameWindowForward() {
        var presented: [NSWindow] = []
        let controller = settings(present: { presented.append($0) })

        controller.show()
        controller.show()

        #expect(presented.count == 2)
        #expect(presented.first === presented.last)
    }

    /// A closed window costs nothing: it is released and built again on the next show.
    @Test func closingReleasesTheWindowAndTheNextShowBuildsAnother() throws {
        let controller = settings()
        controller.show()
        let first = try #require(controller.window)

        first.close()
        #expect(controller.window == nil)
        controller.show()

        #expect(controller.window !== first)
    }

    /// Released means freed: nothing else may keep the window or its SwiftUI content alive.
    @Test func aClosedWindowIsFreed() throws {
        let controller = settings()
        weak var closedWindow: NSWindow?
        weak var closedModel: AccessibilityViewModel?
        try autoreleasepool {
            controller.show()
            closedWindow = controller.window
            closedModel = controller.accessibility
            try #require(controller.window).close()
        }

        #expect(closedWindow == nil)
        #expect(closedModel == nil)
    }

    /// Coming back from System Settings brings the window forward, and the status follows.
    @Test func comingForwardReadsThePermissionAgain() {
        let macOS = PermissionRecorder()
        let controller = settings(macOS)
        controller.show()

        macOS.isTrusted = true
        controller.windowDidBecomeKey(Notification(name: NSWindow.didBecomeKeyNotification))

        #expect(controller.accessibility?.isGranted == true)
    }

    /// SwiftUI lays the content out below the title bar, so the window must be taller than the
    /// content by the bar. Sized before layout, it came out 32pt short and clipped the bottom.
    @Test func theWindowFitsItsContentBelowTheTitleBar() throws {
        let controller = settings()
        controller.show()
        let window = try #require(controller.window)
        let content = try #require(window.contentView)

        content.layoutSubtreeIfNeeded()

        #expect(window.frame.size == content.fittingSize)
    }

    @Test func escapeClosesTheWindow() throws {
        let controller = settings()
        controller.show()

        try #require(controller.window).cancelOperation(nil)

        #expect(controller.window == nil)
    }

    /// An agent app has no main menu, so nothing else answers ⌘W. With Russian – PC active
    /// the key types "ц": the key closes the window, not the letter.
    @Test func commandWClosesTheWindowInAnyLayout() throws {
        let controller = settings()
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
