import AppKit
import OSLog

/// Starts a new instance of SmartType once this one has quit, so the two never run side by
/// side. The same approach as SmartDock's.
enum AppRelauncher {
    /// What a relaunch asks the system to run, built apart so a test can read it.
    struct Plan: Equatable {
        let executable: String
        let arguments: [String]
        let environment: [String: String]
    }

    /// Waits up to 5 s for `pid` to exit, then opens the bundle. The path travels in an
    /// environment variable, so quotes or spaces in it cannot become shell syntax.
    static func plan(bundlePath: String, pid: Int32) -> Plan {
        let script = """
            i=0
            while [ $i -lt 50 ] && kill -0 \(pid) 2>/dev/null; do
                /bin/sleep 0.1
                i=$((i+1))
            done
            /usr/bin/open -n "$BUNDLE_PATH"
            """
        return Plan(executable: "/bin/sh", arguments: ["-c", script], environment: ["BUNDLE_PATH": bundlePath])
    }

    static func relaunch() {
        relaunch(
            bundlePath: Bundle.main.bundlePath, pid: ProcessInfo.processInfo.processIdentifier,
            run: { try spawn($0) }, terminate: { NSApp.terminate(nil) })
    }

    /// `run` and `terminate` are parameters: a test can neither spawn a shell nor quit the runner.
    static func relaunch(bundlePath: String, pid: Int32, run: (Plan) throws -> Void, terminate: () -> Void) {
        do {
            try run(plan(bundlePath: bundlePath, pid: pid))
            Log.general.notice("Relaunch scheduled")
            terminate()
        } catch {
            Log.general.error("Relaunch could not be scheduled: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func spawn(_ plan: Plan) throws {
        let process = Process()
        process.executableURL = URL(filePath: plan.executable)
        process.arguments = plan.arguments
        process.environment = plan.environment
        try process.run()
    }
}
