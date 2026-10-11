import AppKit
import Testing

@testable import SmartTypeApp

@Suite struct StatusMenuTests {
    /// `performActionForItem` sends through `NSApp`, which exists only once something creates
    /// it. Without this the result depended on which suite happened to run first.
    init() {
        _ = NSApplication.shared
    }

    private func filledMenu(
        refused: Set<AppCommand> = [],
        perform: @escaping (AppCommand) -> Void = { _ in },
        quit: @escaping () -> Void = {}
    ) -> NSMenu {
        let menu = NSMenu()
        StatusMenu.fill(menu, refusedHotKeys: refused, perform: perform, quit: quit)
        return menu
    }

    @Test(arguments: AppCommand.allCases)
    func everyCommandHasAnItemThatShowsItsHotKey(_ command: AppCommand) throws {
        let item = try #require(filledMenu().items.first { $0.title == command.title })
        #expect(item.keyEquivalent == command.defaultHotKey.key.label.lowercased())
        #expect(item.keyEquivalentModifierMask == command.defaultHotKey.modifiers.eventFlags)
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

        #expect(lines.contains("Fix Layout  ⌃⌥L"))
        #expect(lines.contains("Translate  ⌃⌥T — not registered"))
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

        StatusMenu.fill(menu, refusedHotKeys: [], perform: { _ in }, quit: {})

        #expect(menu.items.count == count)
    }

    @Test func theMenuBarSymbolExists() {
        #expect(NSImage(systemSymbolName: StatusBarController.symbolName, accessibilityDescription: nil) != nil)
    }
}
