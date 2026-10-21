import AppKit

/// The status menu's contents, laid out as SmartDock's: the version and what Fix Layout works
/// between on top, then the commands from `AppCommand`, so none can be left out, then the
/// windows, then Quit. Every row that does something has its icon.
enum StatusMenu {
    /// What the menu shows, read as it opens.
    struct Contents {
        let version: String
        /// The layouts Fix Layout works between, by the names macOS gives them.
        let layoutNames: [String]
        let shortcuts: [AppCommand: KeyCombo]
        let refusedHotKeys: Set<AppCommand>
        let needsAccess: Bool
    }

    /// What its rows do.
    struct Actions {
        let perform: (AppCommand) -> Void
        let grantAccess: () -> Void
        let openSettings: () -> Void
        let openAbout: () -> Void
        let quit: () -> Void
    }

    /// Named once, so a title and its icon cannot drift apart.
    private enum Symbol {
        static let grantAccess = "exclamationmark.triangle"
        static let shortcuts = "keyboard"
        static let settings = "gearshape"
        static let about = "info.circle"
        static let quit = "xmark.circle"
    }

    static func fill(
        _ menu: NSMenu, with contents: Contents, actions: Actions, isAvailable: (AppCommand) -> Bool = \.isAvailable
    ) {
        menu.removeAllItems()
        menu.addItem(header(version: contents.version))
        menu.addItem(note(layoutsLine(contents.layoutNames)))
        menu.addItem(.separator())
        if contents.needsAccess {
            let title = String(
                localized: "Grant Access…",
                comment: "Button and menu item: add SmartType to the Accessibility list and open it")
            menu.addItem(item(title, symbol: Symbol.grantAccess, handler: actions.grantAccess))
            menu.addItem(.separator())
        }
        for command in AppCommand.allCases {
            menu.addItem(
                commandItem(
                    command, shortcut: contents.shortcuts[command], isAvailable: isAvailable(command),
                    perform: actions.perform))
        }
        menu.addItem(.separator())
        menu.addItem(hotKeysItem(shortcuts: contents.shortcuts, refused: contents.refusedHotKeys))
        let settingsTitle = String(localized: "Settings…", comment: "Status menu item that opens the Settings window")
        menu.addItem(item(settingsTitle, symbol: Symbol.settings, key: ",", handler: actions.openSettings))
        let aboutTitle = String(localized: "About SmartType", comment: "Status menu item that opens Settings ▸ About")
        menu.addItem(item(aboutTitle, symbol: Symbol.about, handler: actions.openAbout))
        menu.addItem(.separator())
        let quitTitle = String(localized: "Quit SmartType", comment: "Status menu item")
        menu.addItem(item(quitTitle, symbol: Symbol.quit, key: "q", handler: actions.quit))
    }

    // MARK: - Private

    /// The name and version, as SmartDock's menu starts; nobody clicks it.
    private static func header(version: String) -> NSMenuItem {
        let title = "SmartType v\(version)"
        let row = note(title)
        row.attributedTitle = NSAttributedString(
            string: title, attributes: [.font: NSFont.systemFont(ofSize: 13, weight: .semibold)])
        return row
    }

    /// What ⌃⌥⇧L works between, which the log alone told before; with one layout on, why it
    /// only beeps.
    private static func layoutsLine(_ names: [String]) -> String {
        guard names.count > 1 else {
            return String(
                localized: "Fix Layout needs a second layout",
                comment: "Status menu: under the version, with fewer than two layouts on")
        }
        return names.joined(separator: " ↔ ")
    }

    private static func item(
        _ title: String, symbol: String, key: String = "", handler: @escaping () -> Void
    ) -> NSMenuItem {
        let row = NSMenuItem(title: title, keyEquivalent: key, handler: handler)
        row.setTitle(title, symbol: symbol)
        return row
    }

    /// A command this Mac cannot run stays in the menu, greyed out, saying what it needs. One
    /// without a shortcut shows no keys.
    private static func commandItem(
        _ command: AppCommand, shortcut: KeyCombo?, isAvailable: Bool, perform: @escaping (AppCommand) -> Void
    ) -> NSMenuItem {
        let key = shortcut?.key.menuKeyEquivalent ?? ""
        let row =
            isAvailable
            ? NSMenuItem(title: command.title, keyEquivalent: key) { perform(command) }
            : NSMenuItem(title: command.title, action: nil, keyEquivalent: key)
        row.setTitle(command.title, symbol: command.symbolName)
        row.keyEquivalentModifierMask = shortcut?.modifiers.eventFlags ?? []
        if !isAvailable {
            row.toolTip = command.requirement
        }
        return row
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
        let row = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        row.setTitle(title, symbol: Symbol.shortcuts)
        row.submenu = submenu
        return row
    }

    private static func note(_ title: String) -> NSMenuItem {
        let row = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        row.isEnabled = false
        return row
    }
}
