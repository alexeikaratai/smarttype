import AppKit
import Testing

@testable import SmartTypeApp

@Suite struct AppCompositionTests {
    @Test func startingRegistersTheDefaultHotKeyOfEveryCommand() {
        _ = NSApplication.shared
        let registrar = RecordingRegistrar()
        let composition = AppComposition(hotKeyRegistrar: registrar)
        defer { composition.stop() }

        composition.start()

        #expect(Set(registrar.registered.values) == Set(AppCommand.allCases.map(\.defaultHotKey)))
        #expect(composition.refusedHotKeys.isEmpty)
    }

    /// The relaunch after a reset lands here: only a new process puts SmartType back in the
    /// list. As in SmartDock, Settings opens next to System Settings, to show the status.
    @Test func aStartAfterAResetAsksForAccessAndOpensSettings() {
        _ = NSApplication.shared
        let macOS = PermissionRecorder()
        macOS.permission().asksAfterNextLaunch = true
        var presented = 0
        let composition = AppComposition(
            hotKeyRegistrar: RecordingRegistrar(), permission: macOS.permission(),
            presentSettings: { _ in presented += 1 })
        defer { composition.stop() }

        composition.start()

        #expect(presented == 1)
        #expect(macOS.prompts == 1)
        #expect(macOS.openedURLs.count == 1)
        #expect(!macOS.permission().asksAfterNextLaunch)
    }

    @Test func anOrdinaryStartAsksNothing() {
        _ = NSApplication.shared
        let macOS = PermissionRecorder()
        var presented = 0
        let composition = AppComposition(
            hotKeyRegistrar: RecordingRegistrar(), permission: macOS.permission(),
            presentSettings: { _ in presented += 1 })
        defer { composition.stop() }

        composition.start()

        #expect(macOS.prompts == 0)
        #expect(presented == 0)
    }

    @Test func aHotKeyMacOSRefusesIsReported() {
        _ = NSApplication.shared
        let registrar = RecordingRegistrar()
        registrar.refused = [AppCommand.translate.defaultHotKey]
        let composition = AppComposition(hotKeyRegistrar: registrar)
        defer { composition.stop() }

        composition.start()

        #expect(composition.refusedHotKeys == [.translate])
    }
}
