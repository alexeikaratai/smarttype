import Testing

@testable import SmartTypeApp

@Suite struct AccessibilityViewModelTests {
    /// Read when the window opens and again when it comes forward, never polled.
    @Test func theStatusIsReadAtTheStartAndOnRefreshOnly() {
        let macOS = PermissionRecorder()
        let model = AccessibilityViewModel(permission: macOS.permission(), relaunch: {})
        #expect(!model.isGranted)

        macOS.isTrusted = true
        #expect(!model.isGranted)
        model.refresh()

        #expect(model.isGranted)
    }

    @Test func grantingAccessGoesToMacOS() {
        let macOS = PermissionRecorder()

        AccessibilityViewModel(permission: macOS.permission(), relaunch: {}).requestAccess()

        #expect(macOS.prompts == 1)
        #expect(macOS.openedURLs.count == 1)
    }

    /// After a reset macOS lists SmartType again only for a process started later (measured),
    /// so it relaunches, and the next launch asks.
    @Test func aResetThatWentThroughRelaunchesToAskAgain() async {
        let macOS = PermissionRecorder()
        var relaunches = 0
        let model = AccessibilityViewModel(permission: macOS.permission(), relaunch: { relaunches += 1 })

        await model.reset()

        #expect(macOS.commands.count == 1)
        #expect(relaunches == 1)
        #expect(macOS.permission().asksAfterNextLaunch)
        #expect(macOS.prompts == 0)
        #expect(!model.isShowingResetFailure)
        #expect(!model.isResetting)
    }

    @Test func aFailedResetOffersTheCommandToRunByHand() async {
        let macOS = PermissionRecorder()
        macOS.exitStatus = 1
        let model = AccessibilityViewModel(permission: macOS.permission(), relaunch: {})

        await model.reset()

        #expect(model.isShowingResetFailure)
        #expect(model.manualResetCommand == "tccutil reset Accessibility com.smarttype.app")
        #expect(macOS.prompts == 0)
        #expect(!macOS.permission().asksAfterNextLaunch)
        #expect(!model.isResetting)
    }

    @Test func theStatusIsReadAgainAfterAReset() async {
        let macOS = PermissionRecorder()
        macOS.isTrusted = true
        let model = AccessibilityViewModel(permission: macOS.permission(), relaunch: {})
        macOS.isTrusted = false

        await model.reset()

        #expect(!model.isGranted)
    }
}
