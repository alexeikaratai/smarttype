import Testing

@testable import SmartTypeApp

@Suite struct ShortcutTests {
    @Test func everyCommandIsListedInMenuOrder() {
        #expect(Shortcut.all(refused: []).map(\.command) == AppCommand.allCases)
    }

    @Test func aShortcutMacOSRefusedIsMarked() {
        let shortcuts = Shortcut.all(refused: [.translate])

        #expect(shortcuts.map(\.keys) == ["⌃⌥L", "⌃⌥T"])
        #expect(shortcuts.map(\.isRegistered) == [true, false])
    }
}
