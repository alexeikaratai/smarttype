import AppKit
import Testing

@testable import SmartTypeApp

@Suite struct AppCommandTests {
    /// Decided 2026-10-12: one key more than ⌃⌥, so a stray ⌃⌥L in another app cannot fire it.
    @Test func theDefaultsAreControlOptionShiftLAndT() {
        #expect(AppCommand.fixLayout.defaultHotKey.displayString == "⌃⌥⇧L")
        #expect(AppCommand.translate.defaultHotKey.displayString == "⌃⌥⇧T")
    }

    @Test func everyCommandHasItsOwnHotKey() {
        let hotKeys = AppCommand.allCases.map(\.defaultHotKey)
        #expect(Set(hotKeys).count == hotKeys.count)
    }

    /// Every default passes the rules a person's own shortcut has to pass.
    @Test(arguments: AppCommand.allCases)
    func everyDefaultIsAShortcutTheRulesAccept(_ command: AppCommand) {
        let defaults = Dictionary(uniqueKeysWithValues: AppCommand.allCases.map { ($0, $0.defaultHotKey) })
        #expect(HotKeyRules.problem(with: command.defaultHotKey, for: command, current: defaults, macOS: []) == nil)
    }

    @Test func everyCommandIsStoredUnderItsOwnName() {
        let names = AppCommand.allCases.map(\.storageName)
        #expect(Set(names).count == names.count)
    }

    /// A symbol name that does not exist draws nothing, and the menu row loses its icon.
    @Test(arguments: AppCommand.allCases)
    func everyCommandHasAMenuSymbolThatExists(_ command: AppCommand) {
        #expect(NSImage(systemSymbolName: command.symbolName, accessibilityDescription: nil) != nil)
    }

    @Test func everyCommandHasItsOwnTitle() {
        let titles = AppCommand.allCases.map(\.title)
        #expect(!titles.contains(""))
        #expect(Set(titles).count == titles.count)
    }
}
