import AppKit
import Carbon.HIToolbox
import CoreGraphics
import Foundation
import ServiceManagement

@testable import SmartTypeApp
@testable import SmartTypeEngines

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
/// prompt, opening System Settings, running `tccutil` and relaunching. Nothing reaches the real
/// TCC, and the test run never quits.
final class PermissionRecorder {
    var isTrusted = false
    var exitStatus: Int32 = 0
    private(set) var prompts = 0
    private(set) var relaunches = 0
    private(set) var openedURLs: [URL] = []
    private(set) var commands: [[String]] = []
    /// A defaults domain per test, emptied first and never the app's own.
    private let defaults: UserDefaults

    init(test: String = #function, file: String = #fileID) {
        defaults = .forTest(test, part: "permission", file: file)
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
            },
            relaunch: { self.relaunches += 1 }
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
    /// Runs as ⌘C arrives, for a test that checks what the screen looked like then.
    var onCopy: () -> Void = {}

    /// One pasteboard per test, under a stable name, so runs do not pile them up.
    init(test: String = #function, file: String = #fileID) {
        pasteboard = NSPasteboard(name: .init("com.smarttype.tests.\(file).\(test)"))
        pasteboard.clearContents()
    }

    /// `yielding` suspends at every wait, so a test can press again while a fix is running;
    /// `onPause` sees every wait as it starts, and `holding` can keep one going.
    func clipboard(
        isDenied: Bool = false, yielding: Bool = false, onPause: @escaping (Duration) -> Void = { _ in },
        holding: @escaping (Duration) async -> Void = { _ in }
    ) -> ClipboardTransaction {
        let pause: (Duration) async -> Void = { duration in
            onPause(duration)
            await holding(duration)
            if yielding { await Task.yield() }
        }
        let keystrokes = KeystrokeSender(currentModifiers: { [] }, post: { self.receive($0) }, pause: pause)
        return ClipboardTransaction(
            pasteboard: pasteboard, keystrokes: keystrokes, isDenied: { _ in isDenied }, pause: pause)
    }

    private func receive(_ event: CGEvent) {
        guard event.type == .keyDown, event.flags.contains(.maskCommand) else { return }
        switch Int(event.getIntegerValueField(.keyboardEventKeycode)) {
        case kVK_ANSI_C:
            copies += 1
            onCopy()
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

/// A translation engine that answers with the target's code in front of the text ("en: …"),
/// fails when told to, and can hold its first answer until the test lets it go.
actor FakeTranslationEngine: TranslationEngine {
    nonisolated let name = "Fake"
    private(set) var callCount = 0
    private let failure: TranslationFailure?
    private let holdsFirstAnswer: Bool
    private var held: CheckedContinuation<Void, Never>?
    private var waitingForTheFirstCall: [CheckedContinuation<Void, Never>] = []

    init(failure: TranslationFailure? = nil, holdsFirstAnswer: Bool = false) {
        self.failure = failure
        self.holdsFirstAnswer = holdsFirstAnswer
    }

    func translate(_ text: String, from source: Locale.Language, to target: Locale.Language) async throws -> String {
        callCount += 1
        if holdsFirstAnswer, callCount == 1 {
            await withCheckedContinuation { continuation in
                held = continuation
                for waiting in waitingForTheFirstCall {
                    waiting.resume()
                }
                waitingForTheFirstCall = []
            }
        }
        if let failure { throw failure }
        return "\(target.languageCode?.identifier ?? "?"): \(text)"
    }

    /// Returns once the first call is being held.
    func waitUntilAsked() async {
        guard held == nil else { return }
        await withCheckedContinuation { waitingForTheFirstCall.append($0) }
    }

    func releaseFirstAnswer() {
        held?.resume()
        held = nil
    }
}

extension TranslationChoices {
    static func forTest(_ test: String, file: String = #fileID) -> TranslationChoices {
        TranslationChoices(defaults: .forTest(test, part: "translation", file: file))
    }
}

extension HotKeyStore {
    static func forTest(_ test: String, file: String = #fileID) -> HotKeyStore {
        HotKeyStore(defaults: .forTest(test, part: "hotkeys", file: file))
    }
}

/// Holds a wait until the test opens it.
final class Gate {
    private(set) var isHolding = false
    private var held: CheckedContinuation<Void, Never>?

    func hold() async {
        await withCheckedContinuation { continuation in
            held = continuation
            isHolding = true
        }
    }

    func open() {
        isHolding = false
        held?.resume()
        held = nil
    }
}

/// Stands in for `SMAppService.mainApp`, SmartType's login item, with macOS's answers set by the
/// test. Nothing reaches the person's Login Items, and the test runner never becomes one.
final class LoginItemRecorder: LoginItemRegistering {
    /// macOS answers `notFound` until the first registration (measured).
    var status = SMAppService.Status.notFound
    /// Thrown by the next change, as macOS refuses one; `statusAfterRefusal` is what it reports then.
    var refusal: (any Error)?
    var statusAfterRefusal: SMAppService.Status?
    private(set) var registrations = 0
    private(set) var unregistrations = 0

    func register() throws {
        registrations += 1
        try refuseIfTold()
        status = .enabled
    }

    func unregister() throws {
        unregistrations += 1
        try refuseIfTold()
        status = .notRegistered
    }

    private func refuseIfTold() throws {
        guard let refusal else { return }
        if let statusAfterRefusal { status = statusAfterRefusal }
        throw refusal
    }
}
