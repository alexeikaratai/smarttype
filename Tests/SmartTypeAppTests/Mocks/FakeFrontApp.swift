import AppKit
import Carbon.HIToolbox
import CoreGraphics

@testable import SmartTypeApp

/// Stands in for the frontmost app on a private pasteboard: ⌘C puts its selection there and
/// ⌘V takes whatever is there. No real app, no real keystroke and no real clipboard.
final class FakeFrontApp {
    let pasteboard: NSPasteboard
    /// What ⌘C copies; `nil` means nothing is selected, so ⌘C leaves the pasteboard alone.
    var selection: String?
    /// ⌘C copies an image instead of text, as when a picture is selected.
    var selectsAnImage = false
    /// ⌘C empties the pasteboard and writes nothing, as an app with nothing to copy may.
    var copiesNothingButClears = false
    private(set) var copies = 0
    private(set) var pasted: [String] = []
    /// The pasteboard's types at each ⌘V.
    private(set) var typesAtPaste: [[NSPasteboard.PasteboardType]] = []
    /// Runs as ⌘C arrives, for a test that checks what the screen looked like then.
    var onCopy: () -> Void = {}

    /// One pasteboard per test, under a stable name, so runs do not pile them up.
    init(test: String = #function, file: String = #fileID) {
        pasteboard = NSPasteboard(name: .init("com.smarttype.tests.\(file).\(test)"))
        pasteboard.clearContents()
    }

    /// `yielding` suspends at every wait, so a test can press again while a fix is running;
    /// `onPause` sees every wait as it starts, and `holding` can keep one going.
    /// `currentModifiers` is the keys the person holds, none by default.
    func clipboard(
        isDenied: Bool = false, yielding: Bool = false, onPause: @escaping (Duration) -> Void = { _ in },
        holding: @escaping (Duration) async -> Void = { _ in },
        currentModifiers: @escaping () -> CGEventFlags = { [] }
    ) -> ClipboardTransaction {
        let pause: (Duration) async -> Void = { duration in
            onPause(duration)
            await holding(duration)
            if yielding { await Task.yield() }
        }
        let keystrokes = KeystrokeSender(
            currentModifiers: currentModifiers, keyCode: \.ansiKeyCode, post: { self.receive($0) }, pause: pause)
        return ClipboardTransaction(
            pasteboard: pasteboard, keystrokes: keystrokes, isDenied: { _ in isDenied }, pause: pause)
    }

    private func receive(_ event: CGEvent) {
        guard event.type == .keyDown, event.flags.contains(.maskCommand) else { return }
        switch Int(event.getIntegerValueField(.keyboardEventKeycode)) {
        case kVK_ANSI_C:
            copies += 1
            onCopy()
            if copiesNothingButClears {
                pasteboard.clearContents()
            } else if selectsAnImage {
                pasteboard.clearContents()
                pasteboard.setData(Data([0x89, 0x50, 0x4E, 0x47]), forType: .png)
            } else if let selection {
                pasteboard.clearContents()
                pasteboard.setString(selection, forType: .string)
            }
        case kVK_ANSI_V:
            typesAtPaste.append(pasteboard.types ?? [])
            pasted.append(pasteboard.string(forType: .string) ?? "")
        default:
            break
        }
    }
}
