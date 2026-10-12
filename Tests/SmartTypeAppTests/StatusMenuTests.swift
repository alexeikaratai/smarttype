import AppKit
import Testing

@testable import SmartTypeApp

@Suite struct StatusMenuTests {
    /// `performActionForItem` sends through `NSApp`, which exists only once something creates
    /// it. Without this the result depended on which suite happened to run first.
    init() {
        _ = NSApplication.shared
    }

    private static let defaults = Dictionary(uniqueKeysWithValues: AppCommand.allCases.map { ($0, $0.defaultHotKey) })

    private func filledMenu(
        shortcuts: [AppCommand: KeyCombo] = Self.defaults,
        refused: Set<AppCommand> = [],
        needsAccess: Bool = false,
        perform: @escaping (AppCommand) -> Void = { _ in },
        isAvailable: @escaping (AppCommand) -> Bool = { _ in true },
        grantAccess: @escaping () -> Void = {},
        openSettings: @escaping () -> Void = {},
        quit: @escaping () -> Void = {}
    ) -> NSMenu {
        let menu = NSMenu()
        StatusMenu.fill(
            menu, shortcuts: shortcuts, refusedHotKeys: refused, needsAccess: needsAccess, isAvailable: isAvailable,
            perform: perform, grantAccess: grantAccess, openSettings: openSettings, quit: quit)
        return menu
    }

    @Test(arguments: AppCommand.allCases)
    func everyCommandHasAnItemThatShowsItsHotKey(_ command: AppCommand) throws {
        let item = try #require(filledMenu().items.first { $0.title == command.title })
        #expect(item.keyEquivalent == command.defaultHotKey.key.menuKeyEquivalent)
        #expect(item.keyEquivalentModifierMask == command.defaultHotKey.modifiers.eventFlags)
    }

    /// The shortcut the person set in Settings, not the default.
    @Test func theMenuShowsTheShortcutThePersonSet() throws {
        let f5 = KeyCombo(key: Key(code: 96), modifiers: [.control, .command])
        let menu = filledMenu(shortcuts: [.fixLayout: f5, .translate: AppCommand.translate.defaultHotKey])
        let item = try #require(menu.items.first { $0.title == AppCommand.fixLayout.title })

        #expect(item.keyEquivalent == f5.key.menuKeyEquivalent)
        #expect(item.keyEquivalentModifierMask == [.control, .command])
    }

    /// A command left without a shortcut is still in the menu, with no keys beside it.
    @Test func aCommandWithoutAShortcutShowsNoKeys() throws {
        let menu = filledMenu(shortcuts: [.fixLayout: AppCommand.fixLayout.defaultHotKey])
        let item = try #require(menu.items.first { $0.title == AppCommand.translate.title })
        let submenu = try #require(menu.items.first { $0.title == "Keyboard Shortcuts" }?.submenu)

        #expect(item.keyEquivalent.isEmpty)
        #expect(submenu.items.map(\.title).contains("Translate  None"))
    }

    @Test(arguments: AppCommand.allCases)
    func choosingACommandPerformsThatCommand(_ command: AppCommand) throws {
        var performed: [AppCommand] = []
        let menu = filledMenu { performed.append($0) }
        let index = try #require(menu.items.firstIndex { $0.title == command.title })

        menu.performActionForItem(at: index)

        #expect(performed == [command])
    }

    @Test func theHotKeySettingsListEveryBindingAndWhetherMacOSAcceptedIt() throws {
        let menu = filledMenu(refused: [.translate])
        let submenu = try #require(menu.items.first { $0.title == "Keyboard Shortcuts" }?.submenu)
        let lines = submenu.items.map(\.title)

        #expect(lines.contains("Fix Layout  ⌃⌥⇧L"))
        #expect(lines.contains("Translate  ⌃⌥⇧T — not registered"))
    }

    /// Before macOS 26 there is no engine: Translate stays in the menu, greyed out, saying why.
    @Test func aCommandThisMacCannotRunIsGreyedOutWithTheReason() throws {
        let menu = filledMenu(isAvailable: { $0 != .translate })
        let translate = try #require(menu.items.first { $0.title == AppCommand.translate.title })

        #expect(translate.action == nil)
        #expect(translate.toolTip == "Needs macOS 26")
    }

    /// While SmartType lacks the permission both commands need, the menu says so first.
    @Test func withoutThePermissionTheMenuOffersToGrantItFirst() throws {
        var granted = 0
        let menu = filledMenu(needsAccess: true, grantAccess: { granted += 1 })
        let first = try #require(menu.items.first)

        menu.performActionForItem(at: 0)

        #expect(first.title == "⚠︎ Grant Access…")
        #expect(menu.items[1].isSeparatorItem)
        #expect(granted == 1)
    }

    @Test func withThePermissionTheMenuDoesNotMentionIt() {
        #expect(!filledMenu(needsAccess: false).items.contains { $0.title.hasSuffix("Grant Access…") })
    }

    /// Next to the shortcuts it configures, and on ⌘, as in every Mac app.
    @Test func settingsFollowsTheShortcutsAndAnswersCommandComma() throws {
        var opened = 0
        let menu = filledMenu(openSettings: { opened += 1 })
        let index = try #require(menu.items.firstIndex { $0.title == "Settings…" })
        let settings = menu.items[index]

        menu.performActionForItem(at: index)

        #expect(menu.items[index - 1].title == "Keyboard Shortcuts")
        #expect(settings.keyEquivalent == ",")
        #expect(settings.keyEquivalentModifierMask == .command)
        #expect(opened == 1)
    }

    @Test func quitIsLastAndAnswersCommandQ() throws {
        var didQuit = false
        let menu = filledMenu(quit: { didQuit = true })
        let quit = try #require(menu.items.last)

        menu.performActionForItem(at: menu.items.count - 1)

        #expect(quit.title == "Quit SmartType")
        #expect(quit.keyEquivalent == "q")
        #expect(quit.keyEquivalentModifierMask == .command)
        #expect(didQuit)
    }

    @Test func refillingDoesNotDuplicateItems() {
        let menu = filledMenu()
        let count = menu.items.count

        StatusMenu.fill(
            menu, shortcuts: Self.defaults, refusedHotKeys: [], needsAccess: false, perform: { _ in }, grantAccess: {},
            openSettings: {}, quit: {})

        #expect(menu.items.count == count)
    }

    @Test func theMenuBarSymbolExists() {
        #expect(NSImage(systemSymbolName: StatusBarController.symbolName, accessibilityDescription: nil) != nil)
    }
}
