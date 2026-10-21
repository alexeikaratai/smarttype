import Foundation
import Testing

@testable import SmartTypeApp

@Suite struct AccessibilityPermissionTests {
    @Test func theStatusIsAskedOfMacOSEveryTime() {
        let macOS = PermissionRecorder()
        let accessibility = macOS.permission()
        #expect(!accessibility.isGranted)

        macOS.isTrusted = true

        #expect(accessibility.isGranted)
    }

    /// The prompt puts SmartType in the list, so the person only has to switch it on.
    @Test func requestingAccessPromptsAndOpensThePrivacyPane() {
        let macOS = PermissionRecorder()

        macOS.permission().requestAccess()

        #expect(macOS.prompts == 1)
        #expect(
            macOS.openedURLs.map(\.absoluteString) == [
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            ])
    }

    /// Without the bundle ID, `tccutil reset Accessibility` would reset every app on the Mac.
    @Test func resettingRunsTccutilForThisAppOnly() async {
        let macOS = PermissionRecorder()

        let didReset = await macOS.permission().reset()

        #expect(didReset)
        #expect(macOS.commands == [["/usr/bin/tccutil", "reset", "Accessibility", "com.smarttype.app"]])
    }

    @Test func aResetTccutilRefusesIsReportedAsFailed() async {
        let macOS = PermissionRecorder()
        macOS.exitStatus = 1

        let didReset = await macOS.permission().reset()

        #expect(!didReset)
    }

    /// The real runner, on tools that touch nothing: each path resumes the wait exactly once.
    @Test(arguments: [("/usr/bin/true", Int32(0)), ("/usr/bin/false", 1), ("/nonexistent/tool", -1)])
    func theRunnerReportsHowTheToolEnded(_ path: String, _ status: Int32) async {
        let ended = await AccessibilityPermission.exitStatus(of: URL(filePath: path), [])
        #expect(ended == status)
    }

    /// A flag in the defaults, so it outlives the relaunch that a reset ends with.
    @Test func aRequestCanWaitForTheNextLaunch() {
        let macOS = PermissionRecorder()
        #expect(!macOS.permission().asksAfterNextLaunch)

        macOS.permission().asksAfterNextLaunch = true

        #expect(macOS.permission().asksAfterNextLaunch)
    }

    @Test func theCommandToRunByHandNamesThisApp() {
        #expect(PermissionRecorder().permission().manualResetCommand == "tccutil reset Accessibility com.smarttype.app")
    }

    /// Grant Access, wherever it is pressed. After a rebuild or an update, System Settings keeps
    /// SmartType switched on for a binary that is gone, and only clearing the entry helps; a
    /// stale entry cannot be told from none, so it is always cleared. Only a process started
    /// after that is listed again (measured), so SmartType relaunches and the new one asks.
    @Test func grantingAccessClearsTheEntryAndRelaunchesToAsk() async {
        let macOS = PermissionRecorder()

        let didRelaunch = await macOS.permission().grantAccess()

        #expect(didRelaunch)
        #expect(macOS.commands == [["/usr/bin/tccutil", "reset", "Accessibility", "com.smarttype.app"]])
        #expect(macOS.relaunches == 1)
        #expect(macOS.permission().asksAfterNextLaunch)
        #expect(macOS.prompts == 0)
    }

    /// The entry is cleared but no new process can be started: this one asks, so Grant Access
    /// still opens the list instead of doing nothing.
    @Test func whenTheRelaunchCannotBeScheduledThisProcessAsks() async {
        let macOS = PermissionRecorder()
        macOS.canRelaunch = false

        await macOS.permission().grantAccess()

        #expect(macOS.relaunches == 1)
        #expect(macOS.prompts == 1)
        #expect(macOS.openedURLs.count == 1)
        // This process's request is only checked (measured), so the next launch, by hand, asks.
        #expect(macOS.permission().asksAfterNextLaunch)
    }

    /// `tccutil` refused: asking from this process still lists a SmartType that has no entry.
    @Test func whenTheEntryCannotBeClearedThisProcessAsks() async {
        let macOS = PermissionRecorder()
        macOS.exitStatus = 1

        let didRelaunch = await macOS.permission().grantAccess()

        #expect(!didRelaunch)
        #expect(macOS.relaunches == 0)
        #expect(macOS.prompts == 1)
        #expect(macOS.openedURLs.count == 1)
        #expect(!macOS.permission().asksAfterNextLaunch)
    }
}
