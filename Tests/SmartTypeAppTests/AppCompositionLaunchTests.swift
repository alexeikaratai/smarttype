import AppKit
import Testing

@testable import SmartTypeApp

/// What a launch opens: a window only to show the permission's status, the welcome window until
/// the person has closed it, Settings after.
@Suite struct AppCompositionLaunchTests {
    init() {
        _ = NSApplication.shared
    }

    /// The first launch, for people updating from 0.2 too: the welcome window, and no prompt
    /// nobody asked for.
    @Test func theFirstStartShowsTheWelcome() {
        let macOS = PermissionRecorder()
        var presented: [String] = []
        let composition = AppComposition.forTest(
            #function, macOS: macOS, firstLaunch: .forTest(#function, isDone: false),
            presentSettings: { presented.append($0.title) })
        defer { composition.stop() }

        composition.start()

        #expect(presented == ["Welcome to SmartType"])
        #expect(macOS.prompts == 0)
    }

    /// Grant Access… in the welcome window relaunched SmartType before the window was closed: it
    /// comes back, with the status, instead of Settings.
    @Test func aStartAfterAResetBringsTheWelcomeBackUntilItIsClosed() {
        let macOS = PermissionRecorder()
        macOS.permission().asksAfterNextLaunch = true
        var presented: [String] = []
        let composition = AppComposition.forTest(
            #function, macOS: macOS, firstLaunch: .forTest(#function, isDone: false),
            presentSettings: { presented.append($0.title) })
        defer { composition.stop() }

        composition.start()

        #expect(presented == ["Welcome to SmartType"])
        #expect(macOS.prompts == 1)
    }

    /// The relaunch after a reset lands here: only a new process puts SmartType back in the
    /// list. As in SmartDock, Settings opens next to System Settings, to show the status.
    @Test func aStartAfterAResetAsksForAccessAndOpensSettings() {
        let macOS = PermissionRecorder()
        macOS.permission().asksAfterNextLaunch = true
        var presented: [String] = []
        let composition = AppComposition.forTest(
            #function, macOS: macOS, presentSettings: { presented.append($0.title) })
        defer { composition.stop() }

        composition.start()

        #expect(presented == ["SmartType Settings"])
        #expect(macOS.prompts == 1)
        #expect(macOS.openedURLs.count == 1)
        #expect(!macOS.permission().asksAfterNextLaunch)
    }

    /// The first launch after an update that took the permission: Settings shows it missing, with
    /// Grant Access. No prompt and no System Settings, since the old entry stands there, switched
    /// on, until Grant Access clears it.
    @Test func aStartAfterAnUpdateThatTookThePermissionOpensSettings() {
        let macOS = PermissionRecorder.afterAnUpdateThatTookIt()
        var presented: [String] = []
        let composition = AppComposition.forTest(
            #function, macOS: macOS, presentSettings: { presented.append($0.title) })
        defer { composition.stop() }

        composition.start()

        #expect(presented == ["SmartType Settings"])
        #expect(macOS.prompts == 0)
        #expect(macOS.openedURLs.isEmpty)
    }

    /// The welcome window shows the same status, so it opens alone.
    @Test func anUpdateBeforeTheWelcomeIsClosedShowsOnlyTheWelcome() {
        let macOS = PermissionRecorder.afterAnUpdateThatTookIt()
        var presented: [String] = []
        let composition = AppComposition.forTest(
            #function, macOS: macOS, firstLaunch: .forTest(#function, isDone: false),
            presentSettings: { presented.append($0.title) })
        defer { composition.stop() }

        composition.start()

        #expect(presented == ["Welcome to SmartType"])
    }

    @Test func anOrdinaryStartAsksNothing() {
        let macOS = PermissionRecorder()
        var presented = 0
        let composition = AppComposition.forTest(#function, macOS: macOS, presentSettings: { _ in presented += 1 })
        defer { composition.stop() }

        composition.start()

        #expect(macOS.prompts == 0)
        #expect(presented == 0)
    }
}
