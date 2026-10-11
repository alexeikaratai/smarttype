import OSLog
import Observation

/// What Settings ▸ General shows about Accessibility, and its two fixes. The status is read
/// when the window opens and whenever it comes forward, never polled.
@Observable final class AccessibilityViewModel {
    private(set) var isGranted: Bool
    private(set) var isResetting = false
    /// Raised when the reset did not go through; the alert then offers `manualResetCommand`.
    var isShowingResetFailure = false

    private let permission: AccessibilityPermission
    private let relaunch: () -> Void

    /// `relaunch` has no default: a test that reset with the real one would quit the test run.
    init(permission: AccessibilityPermission, relaunch: @escaping () -> Void) {
        self.permission = permission
        self.relaunch = relaunch
        isGranted = permission.isGranted
    }

    var manualResetCommand: String { permission.manualResetCommand }

    func refresh() {
        isGranted = permission.isGranted
    }

    func requestAccess() {
        Log.permissions.notice("Accessibility: access requested")
        permission.requestAccess()
    }

    /// Clears a stale grant. Only a process started after the reset puts SmartType back in the
    /// list, so SmartType relaunches and asks from there.
    func reset() async {
        isResetting = true
        let didReset = await permission.reset()
        isResetting = false
        Log.permissions.notice("Accessibility: reset \(didReset ? "done" : "refused", privacy: .public)")
        if didReset {
            permission.asksAfterNextLaunch = true
            relaunch()
        } else {
            isShowingResetFailure = true
        }
        // Still current if the relaunch could not be scheduled and SmartType keeps running.
        refresh()
    }
}
