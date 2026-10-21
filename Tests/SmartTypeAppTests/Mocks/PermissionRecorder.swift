import Foundation

@testable import SmartTypeApp

/// Stands in for what `AccessibilityPermission` asks of macOS: the trust check, the system
/// prompt, opening System Settings, running `tccutil` and relaunching. Nothing reaches the real
/// TCC, and the test run never quits.
final class PermissionRecorder {
    var isTrusted = false
    var exitStatus: Int32 = 0
    /// Whether a new instance could be scheduled.
    var canRelaunch = true
    private(set) var prompts = 0
    private(set) var relaunches = 0
    private(set) var openedURLs: [URL] = []
    private(set) var commands: [[String]] = []
    /// A defaults domain per test, emptied first and never the app's own.
    private let defaults: UserDefaults

    init(test: String = #function, file: String = #fileID) {
        defaults = .forTest(test, part: "permission", file: file)
    }

    func permission(bundleID: String = "com.smarttype.app") -> AccessibilityPermission {
        AccessibilityPermission(
            bundleID: bundleID,
            defaults: defaults,
            checkTrust: { self.isTrusted },
            promptForTrust: { self.prompts += 1 },
            openURL: { self.openedURLs.append($0) },
            runTool: { tool, arguments in
                self.commands.append([tool.path] + arguments)
                return self.exitStatus
            },
            relaunch: {
                self.relaunches += 1
                return self.canRelaunch
            }
        )
    }
}
