import Testing

@testable import SmartTypeApp

@Suite struct AppRelauncherTests {
    /// The path travels in the environment, so a quote or a space in it cannot become shell.
    @Test func theNewInstanceStartsOnlyAfterThisOneHasQuit() throws {
        let plan = AppRelauncher.plan(bundlePath: #"/Applications/Smart "Type".app"#, pid: 4242)
        let script = try #require(plan.arguments.last)

        #expect(plan.executable == "/bin/sh")
        #expect(script.contains("kill -0 4242"))
        #expect(script.contains(#"/usr/bin/open -n "$BUNDLE_PATH""#))
        #expect(!script.contains("Smart"))
        #expect(plan.environment == ["BUNDLE_PATH": #"/Applications/Smart "Type".app"#])
    }

    @Test func theAppQuitsOnlyOnceTheRelaunchIsScheduled() {
        var steps: [String] = []

        AppRelauncher.relaunch(
            bundlePath: "/Applications/SmartType.app", pid: 1, run: { _ in steps.append("schedule") },
            terminate: { steps.append("quit") })

        #expect(steps == ["schedule", "quit"])
    }

    @Test func aRelaunchThatCannotBeScheduledKeepsTheAppRunning() {
        struct SpawnFailed: Error {}
        var quit = false

        AppRelauncher.relaunch(
            bundlePath: "/Applications/SmartType.app", pid: 1, run: { _ in throw SpawnFailed() },
            terminate: { quit = true })

        #expect(!quit)
    }
}
