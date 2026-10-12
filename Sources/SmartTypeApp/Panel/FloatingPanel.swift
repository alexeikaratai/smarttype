import AppKit

/// The translation panel: floats over every app and Space, full-screen ones included, and
/// becomes key without activating SmartType, so the app the person is in stays in front.
/// Borderless and clear: the card draws its own glass, corners included.
final class FloatingPanel: NSPanel {
    /// Esc, or a click that took key status somewhere else.
    var onClose: () -> Void = {}

    convenience init() {
        self.init(contentRect: .zero, styleMask: [.nonactivatingPanel, .borderless], backing: .buffered, defer: true)
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
    }

    /// A borderless window never becomes key on its own, and Esc needs key status.
    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onClose()
    }

    override func resignKey() {
        super.resignKey()
        onClose()
    }
}
