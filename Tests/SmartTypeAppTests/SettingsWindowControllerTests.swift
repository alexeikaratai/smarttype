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

    /// About in the menu opens Settings on About, even with the window already open on another
    /// tab; plain Settings… leaves it on the tab it shows.
    @Test func showingOnATabSwitchesToIt() throws {
        let controller = SettingsWindowController.forTest(#function)
        controller.show()
        #expect(controller.navigation?.tab == .general)

        controller.show(tab: .about)
        controller.show()

        #expect(controller.navigation?.tab == .about)
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
        weak var closedShortcuts: ShortcutsViewModel?
        weak var closedNavigation: SettingsNavigation?
        try autoreleasepool {
            controller.show()
            closedWindow = controller.window
            closedModel = controller.accessibility
            closedLoginModel = controller.openAtLogin
            closedTranslationModel = controller.translation
            closedLayoutsModel = controller.layouts
            closedShortcuts = controller.shortcuts
            closedNavigation = controller.navigation
            try #require(controller.window).close()
        }

        #expect(closedWindow == nil)
        await expectFreed([
            ("AccessibilityViewModel", { closedModel == nil }), ("OpenAtLoginViewModel", { closedLoginModel == nil }),
            ("TranslationSettingsModel", { closedTranslationModel == nil }),
            ("LayoutSettingsModel", { closedLayoutsModel == nil }), ("ShortcutsViewModel", { closedShortcuts == nil }),
            ("SettingsNavigation", { closedNavigation == nil }),
        ])
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

    /// A layout may have been turned on in System Settings ▸ Keyboard meanwhile, and the
    /// languages changed in the welcome window.
    @Test func comingForwardReadsTheLayoutsAndLanguagesAgain() throws {
        var enabled = [InputSourceLayout(layout: .usQwerty, name: "U.S.")]
        let controller = SettingsWindowController.forTest(#function, enabled: { enabled })
        controller.show()

        enabled.append(InputSourceLayout(layout: .russianPC, name: "Russian – PC"))
        TranslationChoices.forTest(#function).languages = [Locale.Language(identifier: "pl")]
        controller.windowDidBecomeKey(Notification(name: NSWindow.didBecomeKeyNotification))

        #expect(try #require(controller.layouts).rows.count == 2)
        #expect(controller.translation?.languages.map(\.minimalIdentifier) == ["pl"])
    }

    /// The person went to another app in the middle of a recording: the hotkeys come back
    /// there, instead of staying paused until the window does.
    @Test func leavingTheWindowWhileRecordingBringsTheHotKeysBack() throws {
        let registrar = RecordingRegistrar()
        let hotKeys = HotKeyBindings(registrar: registrar, store: .forTest(#function))
        hotKeys.apply()
        let controller = SettingsWindowController.forTest(#function, hotKeys: hotKeys)
        controller.show()
        try #require(controller.shortcuts).startRecording(.fixLayout)

        controller.windowDidResignKey(Notification(name: NSWindow.didResignKeyNotification))

        #expect(registrar.registered.count == AppCommand.allCases.count)
        #expect(controller.shortcuts?.recording == nil)
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
