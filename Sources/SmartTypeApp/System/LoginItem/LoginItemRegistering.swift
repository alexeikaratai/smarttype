import ServiceManagement

/// SmartType as a login item: `SMAppService.mainApp` in the app, a recorder in a test, so no test
/// run puts the test runner in the person's Login Items (SmartDock).
protocol LoginItemRegistering {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

// MARK: - SMAppService

extension SMAppService: LoginItemRegistering {}
