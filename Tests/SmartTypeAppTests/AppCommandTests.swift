import Testing

@testable import SmartTypeApp

@Suite struct AppCommandTests {
    @Test func everyCommandHasItsOwnHotKey() {
        let hotKeys = AppCommand.allCases.map(\.defaultHotKey)
        #expect(Set(hotKeys).count == hotKeys.count)
    }

    /// Some macOS 15 builds refuse combinations made only of ⌥ or ⌥⇧.
    @Test(arguments: AppCommand.allCases)
    func everyDefaultHotKeyHoldsControlOrCommand(_ command: AppCommand) {
        let modifiers = command.defaultHotKey.modifiers
        #expect(modifiers.contains(.control) || modifiers.contains(.command))
    }

    @Test func everyCommandHasItsOwnTitle() {
        let titles = AppCommand.allCases.map(\.title)
        #expect(!titles.contains(""))
        #expect(Set(titles).count == titles.count)
    }
}
