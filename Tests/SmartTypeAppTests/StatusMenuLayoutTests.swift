import AppKit
import Testing

@testable import SmartTypeApp

/// The menu laid out as SmartDock's: the version and the layouts on top, an icon on every row
/// that does something, and About.
@Suite struct StatusMenuLayoutTests {
    /// `performActionForItem` sends through `NSApp`, which exists only once something creates it.
    init() {
        _ = NSApplication.shared
    }

    /// The version on top and, under it, what Fix Layout works between: two rows nobody clicks,
    /// as in SmartDock's menu.
    @Test func theMenuStartsWithTheVersionAndTheLayouts() {
        let menu = StatusMenu.forTest(layoutNames: ["U.S.", "Russian – PC", "Ukrainian"])

        #expect(menu.items[0].title == "SmartType v1.2.3")
        #expect(menu.items[1].title == "U.S. ↔ Russian – PC ↔ Ukrainian")
        #expect(!menu.items[0].isEnabled)
        #expect(!menu.items[1].isEnabled)
        #expect(menu.items[2].isSeparatorItem)
    }

    /// With one layout on, ⌃⌥⇧L only beeps: the menu says why.
    @Test func withOneLayoutTheMenuAsksForASecond() {
        #expect(StatusMenu.forTest(layoutNames: ["U.S."]).items[1].title == "Fix Layout needs a second layout")
    }

    /// The icon goes inside the attributed title, since macOS 26 draws no `image` in a status
    /// menu (SmartDock measured it); `title` keeps the plain words.
    @Test func everyItemThatDoesSomethingHasItsIcon() {
        let items = StatusMenu.forTest(needsAccess: true).items.filter { !$0.isSeparatorItem && $0.isEnabled }

        #expect(items.count == AppCommand.allCases.count + 5)
        for item in items {
            let icon = item.attributedTitle?.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment
            #expect(icon?.image != nil, "\(item.title) has no icon")
            #expect(!item.title.contains("\t"))
        }
    }

    /// As in SmartDock: About is the last row before Quit. Settings opening on its tab is
    /// `SettingsWindowControllerTests`.
    @Test func aboutIsTheLastRowBeforeQuit() throws {
        var opened = 0
        let menu = StatusMenu.forTest(openAbout: { opened += 1 })
        let index = try #require(menu.items.firstIndex { $0.title == "About SmartType" })

        menu.performActionForItem(at: index)

        #expect(menu.items[index - 1].title == "Settings…")
        #expect(menu.items[index + 1].isSeparatorItem)
        #expect(opened == 1)
    }
}
