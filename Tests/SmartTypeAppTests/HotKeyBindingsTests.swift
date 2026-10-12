import Carbon.HIToolbox
import Testing

@testable import SmartTypeApp

@Suite struct HotKeyBindingsTests {
    private let controlOptionK = KeyCombo(key: Key(code: UInt16(kVK_ANSI_K)), modifiers: [.control, .option])

    private func bindings(_ registrar: RecordingRegistrar, test: String = #function) -> HotKeyBindings {
        HotKeyBindings(registrar: registrar, store: .forTest(test))
    }

    @Test func applyingRegistersEveryCommandsShortcut() {
        let registrar = RecordingRegistrar()

        bindings(registrar).apply()

        #expect(Set(registrar.registered.values) == Set(AppCommand.allCases.map(\.defaultHotKey)))
    }

    @Test func aPressPerformsItsCommand() {
        let registrar = RecordingRegistrar()
        let hotKeys = bindings(registrar)
        var performed: [AppCommand] = []
        hotKeys.perform = { performed.append($0) }
        hotKeys.apply()

        registrar.press(AppCommand.translate.defaultHotKey)

        #expect(performed == [.translate])
    }

    /// A new shortcut works at once, and the old one no longer does.
    @Test func aChangeIsRegisteredAtOnce() {
        let registrar = RecordingRegistrar()
        let hotKeys = bindings(registrar)
        hotKeys.apply()

        hotKeys.set(controlOptionK, for: .fixLayout)

        #expect(Set(registrar.registered.values) == [controlOptionK, AppCommand.translate.defaultHotKey])
        #expect(hotKeys.shortcuts[.fixLayout] == controlOptionK)
    }

    @Test func aClearedCommandHasNoHotKey() {
        let registrar = RecordingRegistrar()
        let hotKeys = bindings(registrar)

        hotKeys.set(nil, for: .translate)

        #expect(Set(registrar.registered.values) == [AppCommand.fixLayout.defaultHotKey])
        #expect(hotKeys.shortcuts[.translate] == nil)
    }

    @Test func resettingBringsTheDefaultBack() {
        let registrar = RecordingRegistrar()
        let hotKeys = bindings(registrar)
        hotKeys.set(controlOptionK, for: .fixLayout)

        hotKeys.reset(.fixLayout)

        #expect(Set(registrar.registered.values) == Set(AppCommand.allCases.map(\.defaultHotKey)))
        #expect(hotKeys.isDefault(.fixLayout))
    }

    /// While Settings records a shortcut, the keys must reach its window, not a hotkey.
    @Test func pausingTakesEveryHotKeyAwayUntilTheyAreApplied() {
        let registrar = RecordingRegistrar()
        let hotKeys = bindings(registrar)
        hotKeys.apply()

        hotKeys.pause()
        #expect(registrar.registered.isEmpty)
        hotKeys.apply()

        #expect(registrar.registered.count == AppCommand.allCases.count)
    }

    @Test func aCombinationMacOSRefusesIsReported() {
        let registrar = RecordingRegistrar()
        registrar.refused = [AppCommand.translate.defaultHotKey]
        let hotKeys = bindings(registrar)

        hotKeys.apply()
        #expect(hotKeys.refused == [.translate])
        hotKeys.set(controlOptionK, for: .translate)

        #expect(hotKeys.refused.isEmpty)
    }
}
