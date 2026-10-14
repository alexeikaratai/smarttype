import CoreGraphics

/// Stands in for the session event tap: what reached it, one line per event, "down 8 ⌘".
final class EventTapRecorder {
    private(set) var events: [String] = []

    func record(_ event: CGEvent) {
        let key = event.getIntegerValueField(.keyboardEventKeycode)
        let command = event.flags.contains(.maskCommand) ? " ⌘" : ""
        events.append("\(event.type == .keyDown ? "down" : "up") \(key)\(command)")
    }
}
