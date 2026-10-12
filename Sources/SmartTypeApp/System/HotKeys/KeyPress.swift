import AppKit

/// A key event as a recording needs it: which key, and the modifiers held.
struct KeyPress: Sendable {
    enum Kind: Sendable {
        case keyDown
        case modifiersChanged
    }

    let kind: Kind
    let keyCode: UInt16
    let modifiers: Modifiers

    init(kind: Kind, keyCode: UInt16, modifiers: Modifiers) {
        self.kind = kind
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// `nil` for anything but a key going down or a modifier changing.
    init?(_ event: NSEvent) {
        switch event.type {
        case .keyDown: kind = .keyDown
        case .flagsChanged: kind = .modifiersChanged
        default: return nil
        }
        keyCode = event.keyCode
        modifiers = Modifiers(eventFlags: event.modifierFlags)
    }
}
