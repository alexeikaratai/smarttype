import AppKit
import Testing

@testable import SmartTypeApp

@Suite struct StatusBarControllerTests {
    init() {
        _ = NSApplication.shared
    }

    @Test func openingTheMenuFillsItWithWhatWasLastShown() throws {
        let controller = StatusBarController(
            permission: PermissionRecorder().permission(), version: "1.2.3", layoutNames: { ["U.S.", "Russian – PC"] })
        defer { controller.remove() }
        var performed: [AppCommand] = []
        var settingsOpened = 0
        let registrar = RecordingRegistrar()
        registrar.refused = [AppCommand.translate.defaultHotKey]
        let hotKeys = HotKeyBindings(registrar: registrar, store: .forTest(#function))
        hotKeys.apply()
        var aboutOpened = 0
        controller.show(
            hotKeys: hotKeys, perform: { performed.append($0) }, openSettings: { settingsOpened += 1 },
            openAbout: { aboutOpened += 1 })
        let menu = NSMenu()

        controller.menuNeedsUpdate(menu)
        // Fix Layout runs on every macOS this one supports; Translate needs macOS 26.
        let fixLayout = try #require(menu.items.firstIndex { $0.title == AppCommand.fixLayout.title })
        menu.performActionForItem(at: fixLayout)
        let settings = try #require(menu.items.firstIndex { $0.title == "Settings…" })
        menu.performActionForItem(at: settings)
        let about = try #require(menu.items.firstIndex { $0.title == "About SmartType" })
        menu.performActionForItem(at: about)

        let submenu = try #require(menu.items.first { $0.submenu != nil }?.submenu)
        #expect(submenu.items.map(\.title).contains("Translate  ⌃⌥⇧T — not registered"))
        #expect(performed == [.fixLayout])
        #expect(settingsOpened == 1)
        #expect(aboutOpened == 1)
        #expect(menu.items.prefix(2).map(\.title) == ["SmartType v1.2.3", "U.S. ↔ Russian – PC"])
    }

    /// The layouts are read as the menu opens, like the permission: one turned on in macOS
    /// shows the next time, with nothing watching in between.
    @Test func theMenuReadsTheLayoutsEachTimeItOpens() {
        var names = ["U.S."]
        let controller = StatusBarController(
            permission: PermissionRecorder().permission(), version: "1.2.3", layoutNames: { names })
        defer { controller.remove() }
        let menu = NSMenu()

        controller.menuNeedsUpdate(menu)
        names.append("Ukrainian")
        controller.menuNeedsUpdate(menu)

        #expect(menu.items[1].title == "U.S. ↔ Ukrainian")
    }

    /// The permission is read each time the menu opens, never polled. Its Grant Access does what
    /// the button in Settings does.
    @Test func theMenuReadsThePermissionEachTimeItOpens() async throws {
        let macOS = PermissionRecorder()
        let controller = StatusBarController(permission: macOS.permission(), version: "1.2.3", layoutNames: { [] })
        defer { controller.remove() }
        controller.show(
            hotKeys: HotKeyBindings(registrar: RecordingRegistrar(), store: .forTest(#function)), perform: { _ in },
            openSettings: {}, openAbout: {})
        let menu = NSMenu()

        controller.menuNeedsUpdate(menu)
        let grant = try #require(menu.items.firstIndex { $0.title.hasSuffix("Grant Access…") })
        menu.performActionForItem(at: grant)
        macOS.isTrusted = true
        controller.menuNeedsUpdate(menu)

        #expect(await waitUntil { macOS.relaunches == 1 })
        #expect(macOS.commands.count == 1)
        #expect(!menu.items.contains { $0.title.hasSuffix("Grant Access…") })
    }
}
