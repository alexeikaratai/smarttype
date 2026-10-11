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

    /// The relaunch after a reset lands here: only a new process puts SmartType back in the list.
    @Test func aStartAfterAResetAsksForAccess() {
        _ = NSApplication.shared
        let macOS = PermissionRecorder()
        macOS.permission().asksAfterNextLaunch = true
        let composition = AppComposition(hotKeyRegistrar: RecordingRegistrar(), permission: macOS.permission())
        defer { composition.stop() }

        composition.start()

        #expect(macOS.prompts == 1)
        #expect(macOS.openedURLs.count == 1)
        #expect(!macOS.permission().asksAfterNextLaunch)
    }

    @Test func anOrdinaryStartAsksNothing() {
        _ = NSApplication.shared
        let macOS = PermissionRecorder()
        let composition = AppComposition(hotKeyRegistrar: RecordingRegistrar(), permission: macOS.permission())
        defer { composition.stop() }

        composition.start()

        #expect(macOS.prompts == 0)
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
