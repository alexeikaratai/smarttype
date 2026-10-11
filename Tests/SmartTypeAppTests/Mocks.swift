import AppKit
import Carbon.HIToolbox
import CoreGraphics
import Foundation

@testable import SmartTypeApp

/// Stands in for Carbon: records what would have been registered, and lets a test press it.
final class RecordingRegistrar: HotKeyRegistering {
    var onPress: ((UInt32) -> Void)?
    var refused: Set<KeyCombo> = []
    private(set) var registered: [UInt32: KeyCombo] = [:]

    func register(_ combo: KeyCombo, id: UInt32) -> Bool {
        guard !refused.contains(combo) else { return false }
        registered[id] = combo
        return true
    }

    func unregisterAll() {
        registered.removeAll()
    }

    /// What Carbon does when the person presses a registered combination.
    func press(_ combo: KeyCombo) {
        for (id, registeredCombo) in registered where registeredCombo == combo {
            onPress?(id)
        }
    }
}

/// Stands in for what `AccessibilityPermission` asks of macOS: the trust check, the system
/// prompt, opening System Settings and running `tccutil`. Nothing reaches the real TCC.
final class PermissionRecorder {
    var isTrusted = false
    var exitStatus: Int32 = 0
    private(set) var prompts = 0
    private(set) var openedURLs: [URL] = []
    private(set) var commands: [[String]] = []
    /// A defaults domain per test, emptied first and never the app's own.
    private let defaults: UserDefaults

    init(test: String = #function, file: String = #fileID) {
        let suite = "com.smarttype.tests.\(file).\(test)".replacingOccurrences(of: "/", with: ".")
        defaults = UserDefaults(suiteName: suite) ?? UserDefaults()
        defaults.removePersistentDomain(forName: suite)
    }

    func permission(bundleID: String = "com.smarttype.app") -> AccessibilityPermission {
        AccessibilityPermission(
            bundleID: bundleID,
            defaults: defaults,
            checkTrust: { self.isTrusted },
            promptForTrust: { self.prompts += 1 },
            openURL: { self.openedURLs.append($0) },
            runTool: { tool, arguments in
                self.commands.append([tool.path] + arguments)
                return self.exitStatus
            }
        )
    }
}

/// Stands in for the frontmost app on a private pasteboard: ⌘C puts its selection there and
/// ⌘V takes whatever is there. No real app, no real keystroke and no real clipboard.
final class FakeFrontApp {
    let pasteboard: NSPasteboard
    /// What ⌘C copies; `nil` means nothing is selected, so ⌘C leaves the pasteboard alone.
    var selection: String?
    /// ⌘C copies an image instead of text, as when a picture is selected.
    var selectsAnImage = false
    private(set) var copies = 0
    private(set) var pasted: [String] = []
    /// The pasteboard's types at each ⌘V.
    private(set) var typesAtPaste: [[NSPasteboard.PasteboardType]] = []

    /// One pasteboard per test, under a stable name, so runs do not pile them up.
    init(test: String = #function, file: String = #fileID) {
        pasteboard = NSPasteboard(name: .init("com.smarttype.tests.\(file).\(test)"))
        pasteboard.clearContents()
    }

    /// `yielding` suspends at every wait, so a test can press again while a fix is running.
    func clipboard(isDenied: Bool = false, yielding: Bool = false) -> ClipboardTransaction {
        let pause: (Duration) async -> Void = { _ in if yielding { await Task.yield() } }
        let keystrokes = KeystrokeSender(currentModifiers: { [] }, post: { self.receive($0) }, pause: pause)
        return ClipboardTransaction(
            pasteboard: pasteboard, keystrokes: keystrokes, isDenied: { _ in isDenied }, pause: pause)
    }

    private func receive(_ event: CGEvent) {
        guard event.type == .keyDown, event.flags.contains(.maskCommand) else { return }
        switch Int(event.getIntegerValueField(.keyboardEventKeycode)) {
        case kVK_ANSI_C:
            copies += 1
            if selectsAnImage {
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
