@testable import SmartTypeApp

/// Stands in for the key monitor a shortcut recording uses: whether one is watching, and presses
/// for it.
final class KeyMonitorRecorder {
    var watching = 0
    private var handler: ((KeyPress) -> Bool)?

    func watch(_ handler: @escaping (KeyPress) -> Bool) -> () -> Void {
        watching += 1
        self.handler = handler
        return { self.watching -= 1 }
    }

    @discardableResult
    func press(_ code: Int, _ modifiers: Modifiers = []) -> Bool {
        handler?(KeyPress(kind: .keyDown, keyCode: UInt16(code), modifiers: modifiers)) ?? false
    }

    func hold(_ modifiers: Modifiers) {
        _ = handler?(KeyPress(kind: .modifiersChanged, keyCode: 0, modifiers: modifiers))
    }
}
