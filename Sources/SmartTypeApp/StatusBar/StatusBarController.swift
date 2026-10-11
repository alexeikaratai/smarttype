import AppKit

/// The menu-bar icon. Its menu is refilled each time it opens, so state-driven items stay
/// current without anything running in between.
final class StatusBarController: NSObject, NSMenuDelegate {
    /// SF Symbol for the menu-bar icon; a test pins that it exists, since a missing one
    /// would leave an invisible status item.
    static let symbolName = "character.cursor.ibeam"

    private let statusBar: NSStatusBar
    private let statusItem: NSStatusItem
    private let permission: AccessibilityPermission
    private var refusedHotKeys: Set<AppCommand> = []
    private var perform: (AppCommand) -> Void = { _ in }
    private var openSettings: () -> Void = {}

    init(statusBar: NSStatusBar = .system, permission: AccessibilityPermission = AccessibilityPermission()) {
        self.statusBar = statusBar
        self.permission = permission
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        statusItem.button?.image = NSImage(systemSymbolName: Self.symbolName, accessibilityDescription: "SmartType")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func show(
        refusedHotKeys: Set<AppCommand>, perform: @escaping (AppCommand) -> Void, openSettings: @escaping () -> Void
    ) {
        self.refusedHotKeys = refusedHotKeys
        self.perform = perform
        self.openSettings = openSettings
    }

    func remove() {
        statusBar.removeStatusItem(statusItem)
    }

    /// The permission is read here, as the menu opens, and never polled.
    func menuNeedsUpdate(_ menu: NSMenu) {
        StatusMenu.fill(
            menu, refusedHotKeys: refusedHotKeys, needsAccess: !permission.isGranted, perform: perform,
            grantAccess: { [permission] in permission.requestAccess() }, openSettings: openSettings,
            quit: { NSApp.terminate(nil) })
    }
}
