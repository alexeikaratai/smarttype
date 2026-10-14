import ServiceManagement

@testable import SmartTypeApp

/// Stands in for `SMAppService.mainApp`, SmartType's login item, with macOS's answers set by the
/// test. Nothing reaches the person's Login Items, and the test runner never becomes one.
final class LoginItemRecorder: LoginItemRegistering {
    /// macOS answers `notFound` until the first registration (measured).
    var status = SMAppService.Status.notFound
    /// Thrown by the next change, as macOS refuses one; `statusAfterRefusal` is what it reports then.
    var refusal: (any Error)?
    var statusAfterRefusal: SMAppService.Status?
    private(set) var registrations = 0
    private(set) var unregistrations = 0

    func register() throws {
        registrations += 1
        try refuseIfTold()
        status = .enabled
    }

    func unregister() throws {
        unregistrations += 1
        try refuseIfTold()
        status = .notRegistered
    }

    private func refuseIfTold() throws {
        guard let refusal else { return }
        if let statusAfterRefusal { status = statusAfterRefusal }
        throw refusal
    }
}
