import Testing

@testable import SmartTypeApp

@Suite struct AccessibilityViewModelTests {
    /// Read when the window opens and again when it comes forward, never polled.
    @Test func theStatusIsReadAtTheStartAndOnRefreshOnly() {
        let macOS = PermissionRecorder()
        let model = AccessibilityViewModel(permission: macOS.permission())
        #expect(!model.isGranted)

        macOS.isTrusted = true
        #expect(!model.isGranted)
        model.refresh()

        #expect(model.isGranted)
    }

    /// The one button: the entry is cleared, SmartType relaunches, and the next launch asks.
    @Test func grantingAccessRelaunchesToAsk() async {
        let macOS = PermissionRecorder()
        let model = AccessibilityViewModel(permission: macOS.permission())

        await model.grantAccess()

        #expect(macOS.commands.count == 1)
        #expect(macOS.relaunches == 1)
        #expect(!model.isShowingResetFailure)
        #expect(!model.isGranting)
    }

    @Test func whenTheEntryCannotBeClearedTheCommandIsOffered() async {
        let macOS = PermissionRecorder()
        macOS.exitStatus = 1
        let model = AccessibilityViewModel(permission: macOS.permission())

        await model.grantAccess()

        #expect(model.isShowingResetFailure)
        #expect(model.manualResetCommand == "tccutil reset Accessibility com.smarttype.app")
        #expect(macOS.relaunches == 0)
        #expect(!model.isGranting)
    }

    @Test func theStatusIsReadAgainAfterGranting() async {
        let macOS = PermissionRecorder()
        macOS.isTrusted = true
        let model = AccessibilityViewModel(permission: macOS.permission())
        macOS.isTrusted = false

        await model.grantAccess()

        #expect(!model.isGranted)
    }
}
