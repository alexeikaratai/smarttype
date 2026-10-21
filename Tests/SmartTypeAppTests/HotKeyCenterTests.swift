import Testing

@testable import SmartTypeApp

@Suite struct HotKeyCenterTests {
    private let fix = KeyCombo(key: .l, modifiers: [.control, .option])
    private let translate = KeyCombo(key: .t, modifiers: [.control, .option])

    @Test func aPressRunsTheActionOfThatCombinationOnly() {
        let registrar = RecordingRegistrar()
        let center = HotKeyCenter(registrar: registrar)
        var fired: [String] = []
        center.register(fix) { fired.append("fix") }
        center.register(translate) { fired.append("translate") }

        registrar.press(translate)

        #expect(fired == ["translate"])
    }

    @Test func everyRegistrationGetsItsOwnIdentifier() {
        let registrar = RecordingRegistrar()
        let center = HotKeyCenter(registrar: registrar)
        center.register(fix) {}
        center.register(translate) {}

        #expect(registrar.registered.count == 2)
        #expect(Set(registrar.registered.values) == [fix, translate])
    }

    @Test func aRefusedCombinationReportsFalseAndNeverFires() throws {
        let registrar = RecordingRegistrar()
        registrar.refused = [fix]
        let center = HotKeyCenter(registrar: registrar)
        var fired = false

        let isRegistered = center.register(fix) { fired = true }
        registrar.onPress?(try #require(registrar.asked[fix]))

        #expect(!isRegistered)
        #expect(!fired)
    }

    @Test func unregisteringForgetsEveryAction() throws {
        let registrar = RecordingRegistrar()
        let center = HotKeyCenter(registrar: registrar)
        var fired = false
        center.register(fix) { fired = true }

        center.unregisterAll()
        registrar.onPress?(try #require(registrar.asked[fix]))

        #expect(registrar.registered.isEmpty)
        #expect(!fired)
    }
}
