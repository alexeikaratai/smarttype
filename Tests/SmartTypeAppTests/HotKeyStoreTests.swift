import Carbon.HIToolbox
import Foundation
import Testing

@testable import SmartTypeApp

@Suite struct HotKeyStoreTests {
    private let controlOptionK = KeyCombo(key: Key(code: UInt16(kVK_ANSI_K)), modifiers: [.control, .option])

    @Test(arguments: AppCommand.allCases)
    func nothingStoredMeansTheDefault(_ command: AppCommand) {
        #expect(HotKeyStore.forTest("\(#function)-\(command)").shortcut(for: command) == command.defaultHotKey)
    }

    /// Kept for the next launch, in the frozen form: `{keyCode, modifiers}`.
    @Test func aShortcutIsKeptForTheNextLaunch() {
        let defaults = UserDefaults.forTest(#function, part: "hotkeys")

        HotKeyStore(defaults: defaults).set(controlOptionK, for: .fixLayout)

        #expect(HotKeyStore(defaults: defaults).shortcut(for: .fixLayout) == controlOptionK)
        #expect(defaults.object(forKey: "com.smarttype.shortcut.fixLayout") as? [String: Int] == controlOptionK.storage)
    }

    /// A command can be left without a shortcut: `{}`, which is not the same as nothing stored.
    @Test func aClearedShortcutStaysCleared() {
        let defaults = UserDefaults.forTest(#function, part: "hotkeys")

        HotKeyStore(defaults: defaults).set(nil, for: .translate)

        #expect(HotKeyStore(defaults: defaults).shortcut(for: .translate) == nil)
        #expect(defaults.object(forKey: "com.smarttype.shortcut.translate") as? [String: Int] == [:])
    }

    /// Nothing is stored for the default, so a later default reaches everyone who never changed it.
    @Test func theDefaultIsNeverStored() {
        let defaults = UserDefaults.forTest(#function, part: "hotkeys")
        let store = HotKeyStore(defaults: defaults)
        store.set(controlOptionK, for: .fixLayout)
        #expect(!store.isDefault(.fixLayout))

        store.set(AppCommand.fixLayout.defaultHotKey, for: .fixLayout)

        #expect(store.isDefault(.fixLayout))
        #expect(defaults.object(forKey: "com.smarttype.shortcut.fixLayout") == nil)
    }

    @Test func resetGoesBackToTheDefault() {
        let store = HotKeyStore.forTest(#function)
        store.set(nil, for: .fixLayout)

        store.reset(.fixLayout)

        #expect(store.shortcut(for: .fixLayout) == AppCommand.fixLayout.defaultHotKey)
        #expect(store.isDefault(.fixLayout))
    }

    @Test func aValueThisVersionCannotReadMeansTheDefault() {
        let defaults = UserDefaults.forTest(#function, part: "hotkeys")
        defaults.set("⌃⌥L", forKey: "com.smarttype.shortcut.fixLayout")
        defaults.set(["keyCode": 999, "modifiers": 3], forKey: "com.smarttype.shortcut.translate")
        let store = HotKeyStore(defaults: defaults)

        #expect(store.shortcut(for: .fixLayout) == AppCommand.fixLayout.defaultHotKey)
        #expect(store.shortcut(for: .translate) == AppCommand.translate.defaultHotKey)
    }

    /// Renaming a command in code must not lose the shortcut a person set for it.
    @Test func theKeysAreFrozen() {
        #expect(HotKeyStore.key(for: .fixLayout) == "com.smarttype.shortcut.fixLayout")
        #expect(HotKeyStore.key(for: .translate) == "com.smarttype.shortcut.translate")
    }
}
