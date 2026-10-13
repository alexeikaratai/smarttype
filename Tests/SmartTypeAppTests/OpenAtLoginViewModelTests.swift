import ServiceManagement
import Testing

@testable import SmartTypeApp

@Suite struct OpenAtLoginViewModelTests {
    private struct Refused: Error {}

    private func model(_ loginItem: LoginItemRecorder, opened: @escaping () -> Void = {}) -> OpenAtLoginViewModel {
        OpenAtLoginViewModel(loginItem: loginItem, openLoginItems: opened)
    }

    /// Off until the person turns it on (decided 2026-10-13): opening Settings registers nothing.
    @Test func itIsOffUntilThePersonTurnsItOn() {
        let loginItem = LoginItemRecorder()
        let openAtLogin = model(loginItem)

        #expect(!openAtLogin.isOn)
        #expect(openAtLogin.problem == nil)
        #expect(loginItem.registrations == 0)
    }

    /// macOS says `notFound` before the first registration and `notRegistered` once one is undone
    /// (measured with an ad-hoc signed probe); both mean off, and neither is a problem.
    @Test(arguments: [SMAppService.Status.notFound, .notRegistered])
    func neverAndNoLongerRegisteredBothReadAsOff(_ status: SMAppService.Status) {
        let loginItem = LoginItemRecorder()
        loginItem.status = status
        let openAtLogin = model(loginItem)

        #expect(!openAtLogin.isOn)
        #expect(openAtLogin.problem == nil)
    }

    @Test func turningItOnRegistersSmartType() {
        let loginItem = LoginItemRecorder()
        let openAtLogin = model(loginItem)

        openAtLogin.set(true)

        #expect(loginItem.registrations == 1)
        #expect(openAtLogin.isOn)
    }

    @Test func turningItOffUnregistersSmartType() {
        let loginItem = LoginItemRecorder()
        loginItem.status = .enabled
        let openAtLogin = model(loginItem)

        openAtLogin.set(false)

        #expect(loginItem.unregistrations == 1)
        #expect(!openAtLogin.isOn)
    }

    /// The switch shows what macOS reports after a refusal, and the line under it says why.
    @Test func aRefusalLeavesTheSwitchWhereMacOSLeftItAndSaysSo() {
        let loginItem = LoginItemRecorder()
        loginItem.refusal = Refused()
        let openAtLogin = model(loginItem)

        openAtLogin.set(true)

        #expect(!openAtLogin.isOn)
        #expect(openAtLogin.problem == .refused)
    }

    /// Turned off in System Settings' Login Items, SmartType cannot turn itself back on: the person
    /// is sent there.
    @Test func turnedOffInSystemSettingsSendsThePersonThere() {
        let loginItem = LoginItemRecorder()
        loginItem.status = .requiresApproval
        var opened = 0
        let openAtLogin = model(loginItem, opened: { opened += 1 })

        openAtLogin.openLoginItems()

        #expect(!openAtLogin.isOn)
        #expect(openAtLogin.problem == .needsApproval)
        #expect(opened == 1)
    }

    /// A refusal because of System Settings reads as that, not as a failure to try again.
    @Test func aRefusalForApprovalReadsAsNeedingApproval() {
        let loginItem = LoginItemRecorder()
        loginItem.refusal = Refused()
        loginItem.statusAfterRefusal = .requiresApproval
        let openAtLogin = model(loginItem)

        openAtLogin.set(true)

        #expect(openAtLogin.problem == .needsApproval)
    }

    /// Read again on refresh: the person may have changed it in System Settings meanwhile.
    @Test func refreshReadsMacOSAgain() {
        let loginItem = LoginItemRecorder()
        let openAtLogin = model(loginItem)

        loginItem.status = .enabled
        openAtLogin.refresh()

        #expect(openAtLogin.isOn)
    }
}
