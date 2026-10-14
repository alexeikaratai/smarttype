import AppKit

extension NSMenuItem {
    /// A menu item that runs a closure, so menus need no `@objc` selectors of their own.
    ///
    /// A convenience initializer rather than a subclass: `NSMenuItem`'s designated
    /// initializers are nonisolated, and overriding them from this main-actor module is an error.
    convenience init(title: String, keyEquivalent: String = "", handler: @escaping () -> Void) {
        let action = MenuAction(handler)
        self.init(title: title, action: #selector(MenuAction.invoke), keyEquivalent: keyEquivalent)
        target = action
        // `target` is weak; the represented object keeps the action alive as long as the item.
        representedObject = action
    }
}

// MARK: - MenuAction

private final class MenuAction: NSObject {
    private let handler: () -> Void

    init(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    @objc func invoke() {
        handler()
    }
}
