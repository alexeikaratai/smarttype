import AppKit
import OSLog
import SmartTypeCore

/// ⌃⌥L: retypes the selected text as the other keyboard layout would have typed it, then
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
    private let selectLayout: (String) -> Bool
    private let isSmartTypeFrontmost: () -> Bool
    private let beep: () -> Void
    private let explain: (Onboarding.Problem) -> Bool
    private var isRunning = false

    init(
        corrector: LayoutCorrector,
        clipboard: ClipboardTransaction = ClipboardTransaction(),
        permission: AccessibilityPermission = AccessibilityPermission(),
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
        self.selectLayout = selectLayout
        self.isSmartTypeFrontmost = isSmartTypeFrontmost
        self.beep = beep
        self.explain = explain
    }

    /// The core operation, which the right-click Services path shares (Stage 4).
    func fix(_ text: String) -> Correction? {
        corrector.correct(text)
    }

    func fixSelection() async {
        // A press while a fix runs, the hotkey's auto-repeat included, is swallowed.
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }

        guard permission.isGranted else {
            Log.general.notice("Fix Layout: no Accessibility permission")
            if explain(.accessibility) {
                permission.requestAccess()
            }
            return
        }
        // ⌘C would go to SmartType's own window, not to the text the person meant.
        guard !isSmartTypeFrontmost() else { return beep() }

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
    /// for the hotkey's ⌃⌥ to come up.
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
