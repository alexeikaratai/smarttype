import AppKit

/// The status menu's contents, built from `AppCommand` so no command can be left out.
enum StatusMenu {
    static func fill(
        _ menu: NSMenu,
        shortcuts: [AppCommand: KeyCombo],
        refusedHotKeys: Set<AppCommand>,
        needsAccess: Bool,
        isAvailable: (AppCommand) -> Bool = \.isAvailable,
        perform: @escaping (AppCommand) -> Void,
        grantAccess: @escaping () -> Void,
        openSettings: @escaping () -> Void,
        quit: @escaping () -> Void
    ) {
        menu.removeAllItems()
        if needsAccess {
            let grantTitle =
                "⚠︎ "
                + String(
                    localized: "Grant Access…",
                    comment: "Button and menu item: add SmartType to the Accessibility list and open it")
            menu.addItem(NSMenuItem(title: grantTitle, keyEquivalent: "", handler: grantAccess))
            menu.addItem(.separator())
        }
        for command in AppCommand.allCases {
            menu.addItem(
                commandItem(command, shortcut: shortcuts[command], isAvailable: isAvailable(command), perform: perform))
        }
        menu.addItem(.separator())
        menu.addItem(hotKeysItem(shortcuts: shortcuts, refused: refusedHotKeys))
        let settingsTitle = String(localized: "Settings…", comment: "Status menu item that opens the Settings window")
        menu.addItem(NSMenuItem(title: settingsTitle, keyEquivalent: ",", handler: openSettings))
        menu.addItem(.separator())
        let quitTitle = String(localized: "Quit SmartType", comment: "Status menu item")
        menu.addItem(NSMenuItem(title: quitTitle, keyEquivalent: "q", handler: quit))
    }

    /// A command this Mac cannot run stays in the menu, greyed out, saying what it needs. One
    /// without a shortcut shows no keys.
    private static func commandItem(
        _ command: AppCommand, shortcut: KeyCombo?, isAvailable: Bool, perform: @escaping (AppCommand) -> Void
    ) -> NSMenuItem {
        let key = shortcut?.key.menuKeyEquivalent ?? ""
        let item =
            isAvailable
            ? NSMenuItem(title: command.title, keyEquivalent: key) { perform(command) }
            : NSMenuItem(title: command.title, action: nil, keyEquivalent: key)
        item.keyEquivalentModifierMask = shortcut?.modifiers.eventFlags ?? []
        if !isAvailable {
            item.toolTip = command.requirement
        }
        return item
    }

    /// What each command is bound to, and whether macOS accepted it; changed in Settings.
    private static func hotKeysItem(shortcuts: [AppCommand: KeyCombo], refused: Set<AppCommand>) -> NSMenuItem {
        let submenu = NSMenu()
        for command in AppCommand.allCases {
            let refusal = String(localized: "not registered", comment: "After a shortcut macOS refused to register")
            let state = refused.contains(command) ? " — \(refusal)" : ""
            let keys =
                shortcuts[command]?.displayString
                ?? String(localized: "None", comment: "Settings ▸ Shortcuts: a command without a shortcut")
            submenu.addItem(note("\(command.title)  \(keys)\(state)"))
        }
        let title = String(localized: "Keyboard Shortcuts", comment: "Submenu listing the global shortcuts")
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    private static func note(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}
