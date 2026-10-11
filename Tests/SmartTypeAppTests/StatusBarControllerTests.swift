import AppKit
import Testing

@testable import SmartTypeApp

@Suite struct StatusBarControllerTests {
    init() {
        _ = NSApplication.shared
    }

    @Test func openingTheMenuFillsItWithWhatWasLastShown() throws {
        let controller = StatusBarController()
        defer { controller.remove() }
        var performed: [AppCommand] = []
        controller.show(refusedHotKeys: [.fixLayout]) { performed.append($0) }
        let menu = NSMenu()

        controller.menuNeedsUpdate(menu)
        let index = try #require(menu.items.firstIndex { $0.title == AppCommand.translate.title })
        menu.performActionForItem(at: index)

        let submenu = try #require(menu.items.first { $0.submenu != nil }?.submenu)
        #expect(submenu.items.map(\.title).contains("Fix Layout  ⌃⌥L — not registered"))
        #expect(performed == [.translate])
    }
}
