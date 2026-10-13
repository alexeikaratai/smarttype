import OSLog
import Observation
import ServiceManagement

/// What Settings ▸ General shows about Open at Login: off until the person turns it on (decided
/// 2026-10-13), and read from macOS when the window opens or comes forward, never polled.
@Observable final class OpenAtLoginViewModel {
    /// Why the switch did not move, or what keeps it off; said under the switch.
    enum Problem {
        /// Turned off in System Settings' Login Items: only the person can turn it on there.
        case needsApproval
        case refused
    }

    /// As macOS reports it, so a refused change never shows as made.
    private(set) var isOn = false
    private(set) var problem: Problem?

    private let loginItem: any LoginItemRegistering
    private let openSystemSettings: () -> Void

    init(loginItem: any LoginItemRegistering, openLoginItems: @escaping () -> Void) {
        self.loginItem = loginItem
        self.openSystemSettings = openLoginItems
        refresh()
    }

    /// macOS answers `notFound` before the first registration and `notRegistered` once one is
    /// undone (measured with an ad-hoc signed probe): both are off, and neither is a problem.
    func refresh() {
        isOn = loginItem.status == .enabled
        problem = loginItem.status == .requiresApproval ? .needsApproval : nil
    }

    func set(_ isOn: Bool) {
        do {
            if isOn {
                try loginItem.register()
            } else {
                try loginItem.unregister()
            }
            Log.general.notice("Open at Login: \(isOn ? "on" : "off", privacy: .public)")
            refresh()
        } catch {
            Log.general.error("Open at Login: macOS refused, \(error.localizedDescription, privacy: .public)")
            refresh()
            problem = problem ?? .refused
        }
    }

    func openLoginItems() {
        openSystemSettings()
    }
}
