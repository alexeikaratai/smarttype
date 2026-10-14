import Carbon.HIToolbox
import Testing

@testable import SmartTypeApp

@Suite struct HotKeyRulesTests {
    private func combo(_ code: Int, _ modifiers: Modifiers) -> KeyCombo {
        KeyCombo(key: Key(code: UInt16(code)), modifiers: modifiers)
    }

    private func problem(
        _ shortcut: KeyCombo, for command: AppCommand = .fixLayout, macOS: Set<KeyCombo> = []
    ) -> HotKeyProblem? {
        let current = Dictionary(uniqueKeysWithValues: AppCommand.allCases.map { ($0, $0.defaultHotKey) })
        return HotKeyRules.problem(with: shortcut, for: command, current: current, macOS: macOS)
    }

    @Test(arguments: [[.control], [.control, .shift], [.control, .option], [.option, .command], Modifiers.all])
    func controlOrCommandWithOptionMakeAShortcut(_ modifiers: Modifiers) {
        #expect(problem(combo(kVK_ANSI_K, modifiers)) == nil)
    }

    /// ⌘ alone takes keys every app uses: a global ⌘C would stop copying everywhere. Some macOS 15
    /// builds refuse ⌥ or ⌥⇧ alone.
    @Test(arguments: [[], [.shift], [.option], [.option, .shift], [.command], [.command, .shift]] as [Modifiers])
    func otherModifiersAreRefused(_ modifiers: Modifiers) {
        #expect(problem(combo(kVK_ANSI_K, modifiers)) == .needsControlOrCommandOption)
    }

    @Test func aKeyThatCannotMakeAShortcutIsRefused() {
        #expect(problem(combo(kVK_Escape, [.control, .option])) == .unsupportedKey)
    }

    @Test func theOtherCommandsShortcutIsRefused() {
        #expect(problem(AppCommand.translate.defaultHotKey, for: .fixLayout) == .usedBy(.translate))
    }

    @Test func aCommandMayKeepItsOwnShortcut() {
        #expect(problem(AppCommand.fixLayout.defaultHotKey, for: .fixLayout) == nil)
    }

    /// ⌃Space switches input sources (measured in the system's list on this Mac).
    @Test func aShortcutMacOSUsesIsRefused() {
        let inputSources = combo(kVK_Space, [.control])
        #expect(problem(inputSources, macOS: [inputSources]) == .usedByMacOS)
    }

    /// 106 of the 176 shortcuts macOS has switched on also carry fn (0x20000), which a SmartType
    /// shortcut never holds; entries that are no key at all are skipped.
    @Test func macOSShortcutsAreReadWithoutFn() {
        let read = HotKeyRules.shortcuts(from: [
            (code: kVK_Space, carbonModifiers: controlKey), (code: kVK_F11, carbonModifiers: 0x20000),
            (code: kVK_ANSI_K, carbonModifiers: controlKey | 0x20000), (code: -1, carbonModifiers: 0),
        ])

        #expect(read == [combo(kVK_Space, [.control]), combo(kVK_F11, []), combo(kVK_ANSI_K, [.control])])
    }

    @Test(arguments: [
        HotKeyProblem.unsupportedKey, .needsControlOrCommandOption, .usedByMacOS, .usedBy(.translate),
    ])
    func everyRefusalSaysWhy(_ refusal: HotKeyProblem) {
        #expect(!refusal.message.isEmpty)
    }

    @Test func aClashNamesTheOtherCommand() {
        #expect(HotKeyProblem.usedBy(.translate).message.hasSuffix(AppCommand.translate.title))
    }
}
