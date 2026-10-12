import AppKit
import OSLog
import SmartTypeCore

/// Fix Layout (⌃⌥⇧L by default): retypes the selected text as the other keyboard layout would have typed it, then
/// switches to that layout so the person keeps typing in it.
final class LayoutFixAction {
    private enum Outcome {
        case fixed
        case nothingSelected
        case nothingToFix
    }

    private let corrector: LayoutCorrector
    private let clipboard: ClipboardTransaction
    private let permission: AccessibilityPermission
    private let readSelection: () -> String?
    private let selectLayout: (String) -> Bool
    private let isSmartTypeFrontmost: () -> Bool
    private let beep: () -> Void
    private let explain: (Onboarding.Problem) -> Bool
    private var isRunning = false

    init(
        corrector: LayoutCorrector,
        clipboard: ClipboardTransaction,
        permission: AccessibilityPermission,
        readSelection: @escaping () -> String? = { AXSelectionReader.read() },
        selectLayout: @escaping (String) -> Bool = { InputSourceSwitcher.select($0) },
        isSmartTypeFrontmost: @escaping () -> Bool = {
            NSWorkspace.shared.frontmostApplication?.processIdentifier == ProcessInfo.processInfo.processIdentifier
        },
        beep: @escaping () -> Void = { NSSound.beep() },
        explain: @escaping (Onboarding.Problem) -> Bool = { Onboarding.explain($0) }
    ) {
        self.corrector = corrector
        self.clipboard = clipboard
        self.permission = permission
        self.readSelection = readSelection
        self.selectLayout = selectLayout
        self.isSmartTypeFrontmost = isSmartTypeFrontmost
        self.beep = beep
        self.explain = explain
    }

    /// The core operation, which both doors share.
    func fix(_ text: String) -> Correction? {
        corrector.correct(text)
    }

    /// The Services door: macOS hands the text over and puts the fixed text in place itself,
    /// with its own undo, so neither the clipboard nor the keys are touched and no permission
    /// is needed. The keyboard switches, as with the hotkey. `nil`, with a beep, when there is
    /// nothing to fix.
    func fixInPlace(_ text: String) -> String? {
        guard let correction = fix(text) else {
            Log.general.notice("Fix Layout via Services: nothing to fix")
            beep()
            return nil
        }
        let switched = selectLayout(correction.targetLayoutID)
        Log.general.notice(
            "Fix Layout via Services: \(correction.targetLayoutID, privacy: .public) selected: \(switched)")
        return correction.text
    }

    func fixSelection() async {
        // A press while a fix runs, the hotkey's auto-repeat included, is swallowed.
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }
        // Translate has the clipboard: borrowing it now would lose the person's own.
        guard !clipboard.isBorrowed else { return beep() }

        guard permission.isGranted else {
            Log.general.notice("Fix Layout: no Accessibility permission")
            if explain(.accessibility) {
                await permission.grantAccess()
            }
            return
        }
        // ⌘C would go to SmartType's own window, not to the text the person meant.
        guard !isSmartTypeFrontmost() else { return beep() }
        // An app that says nothing is selected gets no ⌘C: VS Code would copy the whole line and
        // the fix retype it, and an app with nothing to copy beeps a second time. A selection it
        // reports may be stale, so what is replaced is still what ⌘C copies.
        if readSelection()?.allSatisfy(\.isWhitespace) == true {
            Log.general.notice("Fix Layout: nothing selected, as Accessibility says")
            return beep()
        }

        let start = ContinuousClock.now
        switch await clipboard.run({ await self.replaceSelection(since: start) }) {
        case nil:
            Log.general.notice("Fix Layout: the clipboard may not be read")
            _ = explain(.pasteboard)
        case .nothingSelected?:
            Log.general.notice("Fix Layout: nothing selected")
            beep()
        case .nothingToFix?:
            Log.general.notice("Fix Layout: nothing to fix")
            beep()
        case .fixed?:
            break  // Logged, and the layout switched, where the text landed.
        }
    }

    /// The timings in the log say where a slow fix spent its time; the copy includes waiting
    /// for the hotkey's modifiers to come up.
    private func replaceSelection(since start: ContinuousClock.Instant) async -> Outcome {
        guard let text = await clipboard.copySelection() else { return .nothingSelected }
        let copied = start.duration(to: .now)
        guard let correction = fix(text) else { return .nothingToFix }
        await clipboard.paste(correction.text)
        // As the text lands, not after the clipboard comes back.
        let switched = selectLayout(correction.targetLayoutID)
        let pasted = start.duration(to: .now)
        Log.general.notice(
            "Fix Layout: copied after \(Int(copied / .milliseconds(1))) ms, pasted after \(Int(pasted / .milliseconds(1))) ms; \(correction.targetLayoutID, privacy: .public) selected: \(switched)"
        )
        return .fixed
    }
}
