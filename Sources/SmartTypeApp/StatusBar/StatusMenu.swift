import AppKit

/// The status menu's contents, built from `AppCommand` so no command can be left out.
enum StatusMenu {
    static func fill(
        _ menu: NSMenu,
        refusedHotKeys: Set<AppCommand>,
        perform: @escaping (AppCommand) -> Void,
        quit: @escaping () -> Void
    ) {
        menu.removeAllItems()
        for command in AppCommand.allCases {
            menu.addItem(commandItem(command, perform: perform))
        }
        menu.addItem(.separator())
        menu.addItem(hotKeysItem(refused: refusedHotKeys))
        menu.addItem(.separator())
        let quitTitle = String(localized: "Quit SmartType", comment: "Status menu item")
        menu.addItem(NSMenuItem(title: quitTitle, keyEquivalent: "q", handler: quit))
    }

    private static func commandItem(_ command: AppCommand, perform: @escaping (AppCommand) -> Void) -> NSMenuItem {
        let combo = command.defaultHotKey
        let item = NSMenuItem(title: command.title, keyEquivalent: combo.key.label.lowercased()) {
            perform(command)
        }
        item.keyEquivalentModifierMask = combo.modifiers.eventFlags
        return item
    }

    /// Read-only for now: what each command is bound to, and whether macOS accepted it.
    private static func hotKeysItem(refused: Set<AppCommand>) -> NSMenuItem {
        let submenu = NSMenu()
        for command in AppCommand.allCases {
            let refusal = String(localized: "not registered", comment: "After a shortcut macOS refused to register")
            let state = refused.contains(command) ? " — \(refusal)" : ""
            submenu.addItem(note("\(command.title)  \(command.defaultHotKey.displayString)\(state)"))
        }
        submenu.addItem(.separator())
        submenu.addItem(
            note(String(localized: "Changing shortcuts comes in a later version", comment: "Shortcuts submenu")))
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
