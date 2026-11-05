import AppKit
import Testing

@testable import SmartTypeApp

@Suite struct AppCompositionTests {
    init() {
        _ = NSApplication.shared
    }

    @Test func startingRegistersTheDefaultHotKeyOfEveryCommand() {
        let registrar = RecordingRegistrar()
        let composition = AppComposition.forTest(#function, registrar: registrar)
        defer { composition.stop() }

        composition.start()

        #expect(Set(registrar.registered.values) == Set(AppCommand.allCases.map(\.defaultHotKey)))
        #expect(composition.refusedHotKeys.isEmpty)
    }

    /// The shortcuts set in Settings come back with the next launch.
    @Test func startingRegistersTheShortcutsThePersonSet() {
        let store = HotKeyStore.forTest(#function)
        let controlOptionK = KeyCombo(key: Key(code: 40), modifiers: [.control, .option])
        store.set(controlOptionK, for: .fixLayout)
        store.set(nil, for: .translate)
        let registrar = RecordingRegistrar()
        let composition = AppComposition.forTest(#function, registrar: registrar, store: store)
        defer { composition.stop() }

        composition.start()

        #expect(Array(registrar.registered.values) == [controlOptionK])
    }

    @Test func aHotKeyMacOSRefusesIsReported() {
        let registrar = RecordingRegistrar()
        registrar.refused = [AppCommand.translate.defaultHotKey]
        let composition = AppComposition.forTest(#function, registrar: registrar)
        defer { composition.stop() }

        composition.start()

        #expect(composition.refusedHotKeys == [.translate])
    }

    /// The right-click Services reach the same two operations as the hotkeys, through one
    /// provider that macOS asks by the names in Info.plist.
    @Test func startingOffersTheServices() throws {
        var offered: [NSObject] = []
        let composition = AppComposition.forTest(#function, offerServices: { offered.append($0) })
        defer { composition.stop() }

        composition.start()

        let provider = try #require(offered.first as? TextServiceProvider)
        #expect(offered.count == 1)
        #expect(provider.responds(to: NSSelectorFromString("fixLayout:userData:error:")))
        #expect(provider.responds(to: NSSelectorFromString("translate:userData:error:")))
    }
}
