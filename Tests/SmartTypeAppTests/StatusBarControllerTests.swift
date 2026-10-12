import AppKit
import Testing

@testable import SmartTypeApp

@Suite struct StatusBarControllerTests {
    init() {
        _ = NSApplication.shared
    }

    @Test func openingTheMenuFillsItWithWhatWasLastShown() throws {
        let controller = StatusBarController(permission: PermissionRecorder().permission())
        defer { controller.remove() }
        var performed: [AppCommand] = []
        var settingsOpened = 0
        let registrar = RecordingRegistrar()
        registrar.refused = [AppCommand.fixLayout.defaultHotKey]
        let hotKeys = HotKeyBindings(registrar: registrar, store: .forTest(#function))
        hotKeys.apply()
        controller.show(hotKeys: hotKeys, perform: { performed.append($0) }, openSettings: { settingsOpened += 1 })
        let menu = NSMenu()

        controller.menuNeedsUpdate(menu)
        let translate = try #require(menu.items.firstIndex { $0.title == AppCommand.translate.title })
        menu.performActionForItem(at: translate)
        let settings = try #require(menu.items.firstIndex { $0.title == "Settings…" })
        menu.performActionForItem(at: settings)

        let submenu = try #require(menu.items.first { $0.submenu != nil }?.submenu)
        #expect(submenu.items.map(\.title).contains("Fix Layout  ⌃⌥⇧L — not registered"))
        #expect(performed == [.translate])
        #expect(settingsOpened == 1)
    }

    /// The permission is read each time the menu opens, never polled.
    @Test func theMenuReadsThePermissionEachTimeItOpens() throws {
        let macOS = PermissionRecorder()
        let controller = StatusBarController(permission: macOS.permission())
        defer { controller.remove() }
        controller.show(
            hotKeys: HotKeyBindings(registrar: RecordingRegistrar(), store: .forTest(#function)), perform: { _ in },
            openSettings: {})
        let menu = NSMenu()

        controller.menuNeedsUpdate(menu)
        let grant = try #require(menu.items.firstIndex { $0.title.hasSuffix("Grant Access…") })
        menu.performActionForItem(at: grant)
        macOS.isTrusted = true
        controller.menuNeedsUpdate(menu)

        #expect(macOS.prompts == 1)
        #expect(!menu.items.contains { $0.title.hasSuffix("Grant Access…") })
    }
}
