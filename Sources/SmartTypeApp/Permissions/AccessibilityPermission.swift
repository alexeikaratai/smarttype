import AppKit
import ApplicationServices
import OSLog

/// Privacy & Security ▸ Accessibility, which both commands need to copy the selection in another
/// app, and Fix Layout to paste the fixed text back.
/// Every call here leaves the process, so each is a parameter whose default is the real thing.
struct AccessibilityPermission {
    /// What to run in Terminal when SmartType could not reset the permission itself.
    let manualResetCommand: String

    private let bundleID: String
    private let defaults: UserDefaults
    private let checkTrust: () -> Bool
    private let promptForTrust: () -> Void
    private let openURL: (URL) -> Void
    private let runTool: (URL, [String]) async -> Int32
    private let relaunch: () -> Void

    private static let tccutil = URL(filePath: "/usr/bin/tccutil")
    private static let privacyPane = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    private static let asksAfterNextLaunchKey = "com.smarttype.asksForAccessibilityAfterNextLaunch"

    /// The fallback ID covers a run outside the app bundle, which has none. `relaunch` has no
    /// default: a test that granted access with the real one would quit the test run, so only
    /// the composition root passes it.
    init(
        bundleID: String = Bundle.main.bundleIdentifier ?? "com.smarttype.app",
        defaults: UserDefaults = .standard,
        checkTrust: @escaping () -> Bool = { AXIsProcessTrusted() },
        promptForTrust: @escaping () -> Void = { AccessibilityPermission.showSystemPrompt() },
        openURL: @escaping (URL) -> Void = { NSWorkspace.shared.open($0) },
        runTool: @escaping (URL, [String]) async -> Int32 = AccessibilityPermission.exitStatus(of:_:),
        relaunch: @escaping () -> Void
    ) {
        // `tccutil reset Accessibility` without an ID resets every app on the Mac.
        precondition(!bundleID.isEmpty, "resetting Accessibility needs this app's bundle ID")
        self.bundleID = bundleID
        self.defaults = defaults
        self.checkTrust = checkTrust
        self.promptForTrust = promptForTrust
        self.openURL = openURL
        self.runTool = runTool
        self.relaunch = relaunch
        manualResetCommand = "tccutil reset Accessibility \(bundleID)"
    }

    /// What System Settings calls the permission. macOS 27 renamed Accessibility to Device
    /// Control and Data Access (measured); the API, the TCC service and the deep link stayed.
    static var settingName: String {
        if #available(macOS 27, *) {
            return String(
                localized: "Device Control and Data Access",
                comment: "The Accessibility permission, named as System Settings names it on macOS 27 and later")
        }
        return String(
            localized: "Accessibility",
            comment: "The Accessibility permission, named as System Settings names it before macOS 27")
    }

    var isGranted: Bool { checkTrust() }

    /// After a reset macOS lists SmartType again only for a process started later (measured
    /// in tccd's log: the same process's request is checked, not registered). So the request
    /// waits for the next launch, in the defaults, across the relaunch.
    var asksAfterNextLaunch: Bool {
        get { defaults.bool(forKey: Self.asksAfterNextLaunchKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.asksAfterNextLaunchKey) }
    }

    /// Puts SmartType in the Accessibility list, where the person only has to switch it on,
    /// and opens that list.
    func requestAccess() {
        promptForTrust()
        if let pane = URL(string: Self.privacyPane) {
            openURL(pane)
        }
    }

    /// Grant Access, wherever it is pressed: Settings, the menu or an alert. After a rebuild or
    /// an update, System Settings keeps SmartType switched on for a binary that is gone, and only
    /// clearing the entry helps. A stale entry cannot be told from none, since the TCC database
    /// is closed to apps, so it is always cleared; with no entry that costs a relaunch. Only a
    /// process started after the reset is listed again (measured), so SmartType relaunches and
    /// the next launch asks. When the entry cannot be cleared, this process asks, and the result
    /// is `false`.
    @discardableResult
    func grantAccess() async -> Bool {
        let didReset = await reset()
        Log.permissions.notice("Accessibility: reset \(didReset ? "done" : "refused", privacy: .public)")
        guard didReset else {
            requestAccess()
            return false
        }
        asksAfterNextLaunch = true
        relaunch()
        return true
    }

    /// Forgets this app's Accessibility decision.
    func reset() async -> Bool {
        await runTool(Self.tccutil, ["reset", "Accessibility", bundleID]) == 0
    }

    /// The literal key: the C constant `kAXTrustedCheckOptionPrompt` is imported as a mutable
    /// global, which Swift 6 rejects.
    static func showSystemPrompt() {
        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    /// Runs a tool without blocking the main thread.
    static func exitStatus(of tool: URL, _ arguments: [String]) async -> Int32 {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = tool
            process.arguments = arguments
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
            do {
                try process.run()
            } catch {
                continuation.resume(returning: -1)
            }
        }
    }
}
