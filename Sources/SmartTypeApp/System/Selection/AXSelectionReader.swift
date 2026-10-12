import AppKit
import ApplicationServices
import OSLog

/// The selected text of the focused element, read through Accessibility: no pasteboard, so the
/// clipboard is not borrowed and macOS asks nothing about pasting (ADR-006). `nil` when the app
/// does not say, and the caller then copies with ⌘C; an empty string when it says nothing is
/// selected, which VS Code answers truthfully (measured), so the caller copies nothing.
enum AXSelectionReader {
    /// A frozen app would otherwise hold each call for AX's default of 6 s.
    private static let timeout: Float = 0.25

    /// The log says what each app answered, never the text, so an app that says nothing is
    /// selected while something is shows up there.
    static func read() -> String? {
        let app = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "?"
        let system = AXUIElementCreateSystemWide()
        // On the system-wide element, this sets the timeout of every call that follows.
        AXUIElementSetMessagingTimeout(system, timeout)
        guard let focused = element(kAXFocusedUIElementAttribute, of: system) else {
            Log.general.notice("Accessibility in \(app, privacy: .public): no focused element")
            return nil
        }
        var selected: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(focused, kAXSelectedTextAttribute as CFString, &selected)
        guard status == .success else {
            Log.general.notice("Accessibility in \(app, privacy: .public): no selected text, error \(status.rawValue)")
            return nil
        }
        let text = selected as? String
        let answer = text.map { $0.isEmpty ? "an empty selection" : "a selection" } ?? "no text"
        Log.general.notice("Accessibility in \(app, privacy: .public): \(answer, privacy: .public)")
        return text
    }

    private static func element(_ attribute: String, of parent: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(parent, attribute as CFString, &value) == .success, let value,
            CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return unsafeDowncast(value, to: AXUIElement.self)
    }
}
