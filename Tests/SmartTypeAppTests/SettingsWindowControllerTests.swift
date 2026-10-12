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
        hotKeys: HotKeyBindings? = nil,
        present: @escaping (NSWindow) -> Void = { _ in },
        test: String = #function
    ) -> SettingsWindowController {
        SettingsWindowController(
            hotKeys: hotKeys ?? HotKeyBindings(registrar: RecordingRegistrar(), store: .forTest(test)),
            permission: macOS.permission(), openURL: { _ in }, present: present)
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
    /// Inside the glass, SwiftUI lets the content go on the run loop's next turn, after the
    /// window (measured: within 50 ms), so the test waits for that.
    @Test func aClosedWindowIsFreed() async throws {
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
        #expect(await waitUntil { closedModel == nil })
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

    /// From macOS 26 the whole window is Liquid Glass: clear itself, with the glass under the
    /// content, so the desktop shows through and the glass follows light and dark.
    @Test func theWindowIsGlassFromMacOS26() throws {
        guard #available(macOS 26, *) else { return }
        let controller = settings()
        controller.show()
        let window = try #require(controller.window)

        #expect(window.contentView is NSGlassEffectView)
        #expect(!window.isOpaque)
        #expect(window.backgroundColor == .clear)
    }

    /// A shortcut was being recorded, so the hotkeys were paused: closing gives them back.
    @Test func closingWhileRecordingBringsTheHotKeysBack() throws {
        let registrar = RecordingRegistrar()
        let hotKeys = HotKeyBindings(registrar: registrar, store: .forTest(#function))
        hotKeys.apply()
        let controller = settings(hotKeys: hotKeys)
        controller.show()
        try #require(controller.shortcuts).startRecording(.fixLayout)
        #expect(registrar.registered.isEmpty)

        try #require(controller.window).close()

        #expect(registrar.registered.count == AppCommand.allCases.count)
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
