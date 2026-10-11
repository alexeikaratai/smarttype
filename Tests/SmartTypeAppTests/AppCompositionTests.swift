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
