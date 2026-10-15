import AppKit
import ServiceManagement
import Testing

@testable import SmartTypeApp
@testable import SmartTypeCore

/// The window's life: built when it opens, freed with its view models when it closes, and read
/// again when it comes forward. How it looks and closes is `SettingsWindowTests`.
@Suite struct SettingsWindowControllerTests {
    init() {
        _ = NSApplication.shared
    }

    @Test func showingTwiceBringsTheSameWindowForward() {
        var presented: [NSWindow] = []
        let controller = SettingsWindowController.forTest(#function, present: { presented.append($0) })

        controller.show()
        controller.show()

        #expect(presented.count == 2)
        #expect(presented.first === presented.last)
    }

    /// A closed window costs nothing: it is released and built again on the next show.
    @Test func closingReleasesTheWindowAndTheNextShowBuildsAnother() throws {
        let controller = SettingsWindowController.forTest(#function)
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
        let controller = SettingsWindowController.forTest(#function)
        weak var closedWindow: NSWindow?
        weak var closedModel: AccessibilityViewModel?
        weak var closedLoginModel: OpenAtLoginViewModel?
        weak var closedTranslationModel: TranslationSettingsModel?
        weak var closedLayoutsModel: LayoutSettingsModel?
        try autoreleasepool {
            controller.show()
            closedWindow = controller.window
            closedModel = controller.accessibility
            closedLoginModel = controller.openAtLogin
            closedTranslationModel = controller.translation
            closedLayoutsModel = controller.layouts
            try #require(controller.window).close()
        }

        #expect(closedWindow == nil)
        #expect(
            await waitUntil {
                closedModel == nil && closedLoginModel == nil && closedTranslationModel == nil
                    && closedLayoutsModel == nil
            })
    }

    /// Open at Login follows too: it may have been changed in System Settings' Login Items.
    @Test func comingForwardReadsOpenAtLoginAgain() {
        let loginItem = LoginItemRecorder()
        let controller = SettingsWindowController.forTest(#function, loginItem: loginItem)
        controller.show()

        loginItem.status = .enabled
        controller.windowDidBecomeKey(Notification(name: NSWindow.didBecomeKeyNotification))

        #expect(controller.openAtLogin?.isOn == true)
    }

    /// Coming back from System Settings brings the window forward, and the status follows.
    @Test func comingForwardReadsThePermissionAgain() {
        let macOS = PermissionRecorder()
        let controller = SettingsWindowController.forTest(#function, macOS: macOS)
        controller.show()

        macOS.isTrusted = true
        controller.windowDidBecomeKey(Notification(name: NSWindow.didBecomeKeyNotification))

        #expect(controller.accessibility?.isGranted == true)
    }

    /// A layout may have been turned on in System Settings ▸ Keyboard meanwhile.
    @Test func comingForwardReadsTheLayoutsAgain() throws {
        var enabled = [InputSourceLayout(layout: .usQwerty, name: "U.S.")]
        let controller = SettingsWindowController(
            hotKeys: HotKeyBindings(registrar: RecordingRegistrar(), store: .forTest(#function)),
            permission: PermissionRecorder().permission(), loginItem: LoginItemRecorder(),
            makeTranslation: { TranslationSettingsModel(choices: .forTest(#function), supportedLanguages: { [] }) },
            makeLayouts: {
                LayoutSettingsModel(choices: .forTest(#function), readEnabled: { enabled }, openURL: { _ in })
            },
            openURL: { _ in }, openLoginItems: {}, present: { _ in })
        controller.show()

        enabled.append(InputSourceLayout(layout: .russianPC, name: "Russian – PC"))
        controller.windowDidBecomeKey(Notification(name: NSWindow.didBecomeKeyNotification))

        #expect(try #require(controller.layouts).rows.count == 2)
    }

    /// A shortcut was being recorded, so the hotkeys were paused: closing gives them back.
    @Test func closingWhileRecordingBringsTheHotKeysBack() throws {
        let registrar = RecordingRegistrar()
        let hotKeys = HotKeyBindings(registrar: registrar, store: .forTest(#function))
        hotKeys.apply()
        let controller = SettingsWindowController.forTest(#function, hotKeys: hotKeys)
        controller.show()
        try #require(controller.shortcuts).startRecording(.fixLayout)
        #expect(registrar.registered.isEmpty)

        try #require(controller.window).close()

        #expect(registrar.registered.count == AppCommand.allCases.count)
    }
}
