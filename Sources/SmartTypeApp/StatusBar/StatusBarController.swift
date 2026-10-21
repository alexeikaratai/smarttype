import AppKit

/// The menu-bar icon. Its menu is refilled each time it opens, so state-driven items stay
/// current without anything running in between.
final class StatusBarController: NSObject {
    /// SF Symbol for the menu-bar icon; a test pins that it exists, since a missing one
    /// would leave an invisible status item.
    static let symbolName = "character.cursor.ibeam"

    private let statusBar: NSStatusBar
    private let statusItem: NSStatusItem
    private let permission: AccessibilityPermission
    private let version: String
    private let layoutNames: () -> [String]
    private var hotKeys: HotKeyBindings?
    private var perform: (AppCommand) -> Void = { _ in }
    private var openSettings: () -> Void = {}
    private var openAbout: () -> Void = {}

    init(
        statusBar: NSStatusBar = .system,
        permission: AccessibilityPermission,
        version: String = AppInfo().version,
        layoutNames: @escaping () -> [String] = { LayoutChoices().switchedOn().map(\.name) }
    ) {
        self.statusBar = statusBar
        self.permission = permission
        self.version = version
        self.layoutNames = layoutNames
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        statusItem.button?.image = NSImage(systemSymbolName: Self.symbolName, accessibilityDescription: "SmartType")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func show(
        hotKeys: HotKeyBindings, perform: @escaping (AppCommand) -> Void, openSettings: @escaping () -> Void,
        openAbout: @escaping () -> Void
    ) {
        self.hotKeys = hotKeys
        self.perform = perform
        self.openSettings = openSettings
        self.openAbout = openAbout
    }

    func remove() {
        statusBar.removeStatusItem(statusItem)
    }
}

// MARK: - NSMenuDelegate

extension StatusBarController: NSMenuDelegate {
    /// The permission, the shortcuts and the layouts are read here, as the menu opens, and
    /// never polled.
    func menuNeedsUpdate(_ menu: NSMenu) {
        StatusMenu.fill(
            menu,
            with: StatusMenu.Contents(
                version: version, layoutNames: layoutNames(), shortcuts: hotKeys?.shortcuts ?? [:],
                refusedHotKeys: hotKeys?.refused ?? [], needsAccess: !permission.isGranted),
            actions: StatusMenu.Actions(
                perform: perform, grantAccess: { [permission] in Task { await permission.grantAccess() } },
                openSettings: openSettings, openAbout: openAbout, quit: { NSApp.terminate(nil) }))
    }
}
