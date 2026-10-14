import AppKit
import Testing

@testable import SmartTypeApp

@Suite struct AppCompositionTests {
    init() {
        _ = NSApplication.shared
    }

    @Test func startingRegistersTheDefaultHotKeyOfEveryCommand() {
        let registrar = RecordingRegistrar()
        let composition = makeComposition(registrar: registrar)
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
        let composition = makeComposition(registrar: registrar, store: store)
        defer { composition.stop() }

        composition.start()

        #expect(Array(registrar.registered.values) == [controlOptionK])
    }

    /// The relaunch after a reset lands here: only a new process puts SmartType back in the
    /// list. As in SmartDock, Settings opens next to System Settings, to show the status.
    @Test func aStartAfterAResetAsksForAccessAndOpensSettings() {
        let macOS = PermissionRecorder()
        macOS.permission().asksAfterNextLaunch = true
        var presented = 0
        let composition = makeComposition(macOS: macOS, presentSettings: { _ in presented += 1 })
        defer { composition.stop() }

        composition.start()

        #expect(presented == 1)
        #expect(macOS.prompts == 1)
        #expect(macOS.openedURLs.count == 1)
        #expect(!macOS.permission().asksAfterNextLaunch)
    }

    @Test func anOrdinaryStartAsksNothing() {
        let macOS = PermissionRecorder()
        var presented = 0
        let composition = makeComposition(macOS: macOS, presentSettings: { _ in presented += 1 })
        defer { composition.stop() }

        composition.start()

        #expect(macOS.prompts == 0)
        #expect(presented == 0)
    }

    @Test func aHotKeyMacOSRefusesIsReported() {
        let registrar = RecordingRegistrar()
        registrar.refused = [AppCommand.translate.defaultHotKey]
        let composition = makeComposition(registrar: registrar)
        defer { composition.stop() }

        composition.start()

        #expect(composition.refusedHotKeys == [.translate])
    }

    /// The right-click Services reach the same two operations as the hotkeys, through one
    /// provider that macOS asks by the names in Info.plist.
    @Test func startingOffersTheServices() throws {
        var offered: [NSObject] = []
        let composition = makeComposition(offerServices: { offered.append($0) })
        defer { composition.stop() }

        composition.start()

        let provider = try #require(offered.first as? TextServiceProvider)
        #expect(offered.count == 1)
        #expect(provider.responds(to: NSSelectorFromString("fixLayout:userData:error:")))
        #expect(provider.responds(to: NSSelectorFromString("translate:userData:error:")))
    }

    /// Recorders for everything that leaves the process, so no test reaches the person's
    /// permission, Login Items or screen. Only the status item is real, and `stop` removes it.
    private func makeComposition(
        registrar: RecordingRegistrar = RecordingRegistrar(),
        store: HotKeyStore? = nil,
        macOS: PermissionRecorder? = nil,
        presentSettings: @escaping (NSWindow) -> Void = { _ in },
        offerServices: @escaping (NSObject) -> Void = { _ in },
        test: String = #function
    ) -> AppComposition {
        AppComposition(
            hotKeyRegistrar: registrar,
            hotKeyStore: store ?? .forTest(test),
            permission: (macOS ?? PermissionRecorder(test: test)).permission(),
            loginItem: LoginItemRecorder(),
            presentSettings: presentSettings,
            offerServices: offerServices)
    }
}
