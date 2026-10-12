import Observation

/// What Settings ▸ General shows about Accessibility, and its one fix. The status is read when
/// the window opens and whenever it comes forward, never polled.
@Observable final class AccessibilityViewModel {
    private(set) var isGranted: Bool
    private(set) var isGranting = false
    /// Raised when the entry could not be cleared; the alert then offers `manualResetCommand`.
    var isShowingResetFailure = false

    private let permission: AccessibilityPermission

    init(permission: AccessibilityPermission) {
        self.permission = permission
        isGranted = permission.isGranted
    }

    var manualResetCommand: String { permission.manualResetCommand }

    func refresh() {
        isGranted = permission.isGranted
    }

    /// SmartType clears its entry and relaunches, and the new process asks; when the entry
    /// cannot be cleared, this one asks and the alert gives the command to run by hand.
    func grantAccess() async {
        isGranting = true
        let didRelaunch = await permission.grantAccess()
        isGranting = false
        if !didRelaunch {
            isShowingResetFailure = true
        }
        // Still current if the relaunch could not be scheduled and SmartType keeps running.
        refresh()
    }
}
