import ApplicationServices

/// The selected text of the focused element, read through Accessibility: no pasteboard, so the
/// clipboard is not borrowed and macOS asks nothing about pasting (ADR-006). `nil` when the app
/// does not say, as Electron apps, terminals and secure fields often do not, or when nothing is
/// selected; the caller then copies with ⌘C.
enum AXSelectionReader {
    /// A frozen app would otherwise hold each call for AX's default of 6 s.
    private static let timeout: Float = 0.25

    static func read() -> String? {
        let system = AXUIElementCreateSystemWide()
        // On the system-wide element, this sets the timeout of every call that follows.
        AXUIElementSetMessagingTimeout(system, timeout)
        guard let focused = element(kAXFocusedUIElementAttribute, of: system) else { return nil }
        var selected: CFTypeRef?
        guard AXUIElementCopyAttributeValue(focused, kAXSelectedTextAttribute as CFString, &selected) == .success
        else { return nil }
        return selected as? String
    }

    private static func element(_ attribute: String, of parent: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(parent, attribute as CFString, &value) == .success, let value,
            CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return unsafeDowncast(value, to: AXUIElement.self)
    }
}
