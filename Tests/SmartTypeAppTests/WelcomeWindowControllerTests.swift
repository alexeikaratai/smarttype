import AppKit
import Testing

@testable import SmartTypeApp
@testable import SmartTypeCore

/// The welcome window's life: built when shown, freed when closed, and closed for good.
@Suite struct WelcomeWindowControllerTests {
    init() {
        _ = NSApplication.shared
    }

    @Test func showingPutsTheWelcomeForward() throws {
        var presented: [NSWindow] = []
        let controller = WelcomeWindowController.forTest(#function, present: { presented.append($0) })

        controller.show()

        let window = try #require(presented.first)
        #expect(window.title == "Welcome to SmartType")
        #expect(window === controller.window)
    }

    /// Closed by the person, with the close button, it does not come back with the next launch.
    @Test func closingIsRememberedAndFreesTheWindow() async throws {
        let firstLaunch = FirstLaunch.forTest(#function, isDone: false)
        let controller = WelcomeWindowController.forTest(#function, firstLaunch: firstLaunch)
        weak var closedWindow: NSWindow?
        weak var closedLayouts: LayoutSettingsModel?
        try autoreleasepool {
            controller.show()
            closedWindow = controller.window
            closedLayouts = controller.layouts
            try #require(controller.window).performClose(nil)
        }

        #expect(firstLaunch.isDone)
        #expect(closedWindow == nil)
        #expect(await waitUntil { closedLayouts == nil })
    }

    /// Quitting closes every window without asking (measured: `windowWillClose` comes, not
    /// `windowShouldClose`), and Grant Access… quits to relaunch: in 0.3.0 that closed the welcome
    /// window for good before the person had seen it through.
    @Test func quittingIsNotClosing() throws {
        let firstLaunch = FirstLaunch.forTest(#function, isDone: false)
        let controller = WelcomeWindowController.forTest(#function, firstLaunch: firstLaunch)
        controller.show()

        try #require(controller.window).close()

        #expect(!firstLaunch.isDone)
        #expect(controller.window == nil)
    }

    @Test func escapeClosesItForGood() throws {
        let firstLaunch = FirstLaunch.forTest(#function, isDone: false)
        let controller = WelcomeWindowController.forTest(#function, firstLaunch: firstLaunch)
        controller.show()

        try #require(controller.window).cancelOperation(nil)

        #expect(firstLaunch.isDone)
    }

    /// Done closes it like the close button.
    @Test func doneClosesIt() throws {
        let firstLaunch = FirstLaunch.forTest(#function, isDone: false)
        let controller = WelcomeWindowController.forTest(#function, firstLaunch: firstLaunch)
        controller.show()

        controller.done()

        #expect(controller.window == nil)
        #expect(firstLaunch.isDone)
    }

    /// Back from System Settings: access may have been allowed, or a layout added.
    @Test func comingForwardReadsAccessAndLayoutsAgain() throws {
        let macOS = PermissionRecorder()
        var enabled = [InputSourceLayout(layout: .usQwerty, name: "U.S.")]
        let controller = WelcomeWindowController.forTest(#function, macOS: macOS, enabled: { enabled })
        controller.show()

        macOS.isTrusted = true
        enabled.append(InputSourceLayout(layout: .russianPC, name: "Russian – PC"))
        controller.windowDidBecomeKey(Notification(name: NSWindow.didBecomeKeyNotification))

        #expect(controller.accessibility?.isGranted == true)
        #expect(try #require(controller.layouts).rows.count == 2)
    }
}
