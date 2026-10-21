import AppKit
import OSLog
import SmartTypeCore

/// Fix Layout (⌃⌥⇧L by default): retypes the selected text as another keyboard layout would
/// have typed it, then switches to that layout so the person keeps typing in it. The layouts
/// are the ones on in Settings ▸ Languages, read afresh on every fix.
final class LayoutFixAction {
    private enum Outcome {
        case fixed
        case nothingSelected
        case nothingToFix
        case keysHeld
    }

    private let makeCorrector: () -> LayoutCorrector
    private let clipboard: ClipboardTransaction
    private let permission: AccessibilityPermission
    private let panel: PanelController
    private let readSelection: () -> String?
    private let selectLayout: (String) -> Bool
    private let isSmartTypeFrontmost: () -> Bool
    private let beep: () -> Void
    private let explain: (Onboarding.Problem) -> Bool
    private var isRunning = false

    init(
        makeCorrector: @escaping () -> LayoutCorrector,
        clipboard: ClipboardTransaction,
        permission: AccessibilityPermission,
        panel: PanelController,
        readSelection: @escaping () -> String? = { AXSelectionReader.read() },
        selectLayout: @escaping (String) -> Bool = { InputSourceSwitcher.select($0) },
        isSmartTypeFrontmost: @escaping () -> Bool = {
            NSWorkspace.shared.frontmostApplication?.processIdentifier == ProcessInfo.processInfo.processIdentifier
        },
        beep: @escaping () -> Void = { NSSound.beep() },
        explain: @escaping (Onboarding.Problem) -> Bool = { Onboarding.explain($0) }
    ) {
        self.makeCorrector = makeCorrector
        self.clipboard = clipboard
        self.permission = permission
        self.panel = panel
        self.readSelection = readSelection
        self.selectLayout = selectLayout
        self.isSmartTypeFrontmost = isSmartTypeFrontmost
        self.beep = beep
        self.explain = explain
    }

    /// The core operation, which both doors share. The log names the layouts it chose between,
    /// which the text never is.
    func fix(_ text: String) -> Correction? {
        let corrector = makeCorrector()
        Log.general.notice("Fix Layout between \(corrector.layoutIDs.joined(separator: ", "), privacy: .public)")
        return corrector.correct(text)
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
        // One layout on leaves nothing to fix between, so no ⌘C either; Settings says why.
        let corrector = makeCorrector()
        guard corrector.canConvert else {
            Log.general.notice(
                "Fix Layout: fewer than two layouts on (\(corrector.layoutIDs.joined(separator: ", "), privacy: .public))"
            )
            return beep()
        }

        guard permission.isGranted else {
            Log.general.notice("Fix Layout: no Accessibility permission")
            if explain(.accessibility) {
                await permission.grantAccess()
            }
            return
        }
        // The panel takes the keys while it is up, without SmartType in front: the ⌘C would
        // go to it. And in SmartType's own window, to that window.
        panel.close()
        guard !isSmartTypeFrontmost() else { return beep() }
        // An app that says nothing is selected gets no ⌘C: VS Code would copy the whole line and
        // the fix retype it, and an app with nothing to copy beeps a second time. A selection it
        // reports may be stale, so what is replaced is still what ⌘C copies.
        if readSelection()?.allSatisfy(\.isWhitespace) == true {
            Log.general.notice("Fix Layout: nothing selected, as Accessibility says")
            return beep()
        }
        await replaceSelectionWithTheClipboardBorrowed()
    }

    // MARK: - Private

    /// Translate may have the clipboard: borrowing it then would lose the person's own. Every
    /// way but a fix ends in a beep, a pasteboard SmartType may not read in an explanation.
    private func replaceSelectionWithTheClipboardBorrowed() async {
        let start = ContinuousClock.now
        do throws(ClipboardTransaction.Refusal) {
            let outcome = try await clipboard.run { await self.replaceSelection(since: start) }
            // A fix is logged, and the layout switched, where the text landed.
            guard outcome != .fixed else { return }
            Log.general.notice("Fix Layout: \(String(describing: outcome), privacy: .public)")
            beep()
        } catch {
            Log.general.notice("Fix Layout: the clipboard was not lent, \(String(describing: error), privacy: .public)")
            if error == .mayNotRead {
                _ = explain(.pasteboard)
            } else {
                beep()
            }
        }
    }

    /// The timings in the log say where a slow fix spent its time; the copy includes waiting
    /// for the hotkey's modifiers to come up.
    private func replaceSelection(since start: ContinuousClock.Instant) async -> Outcome {
        guard let text = await clipboard.copySelection() else { return .nothingSelected }
        let copied = start.duration(to: .now)
        guard let correction = fix(text) else { return .nothingToFix }
        // Right before ⌘V, not after the clipboard comes back: ⌘V then goes on its key in the
        // layout the app reads it in, which Dvorak and Turkish F put on other keys than U.S.
        var switched = false
        let isPasted = await clipboard.paste(correction.text) {
            switched = self.selectLayout(correction.targetLayoutID)
        }
        guard isPasted else { return .keysHeld }
        let pasted = start.duration(to: .now)
        Log.general.notice(
            "Fix Layout: copied after \(Int(copied / .milliseconds(1))) ms, pasted after \(Int(pasted / .milliseconds(1))) ms; \(correction.targetLayoutID, privacy: .public) selected: \(switched)"
        )
        return .fixed
    }
}
