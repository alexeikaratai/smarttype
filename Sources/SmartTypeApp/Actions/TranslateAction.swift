import AppKit
import OSLog
import SmartTypeEngines

/// Translate (⌃⌥⇧T by default): translates the selected text in a panel at the pointer. The selection is copied the
/// same way as for the layout fix, and the clipboard is given back.
final class TranslateAction {
    private let makeCard: (String) -> TranslationViewModel
    private let clipboard: ClipboardTransaction
    private let permission: AccessibilityPermission
    private let panel: PanelController
    private let isAvailable: () -> Bool
    private let isSmartTypeFrontmost: () -> Bool
    private let beep: () -> Void
    private let explain: (Onboarding.Problem) -> Bool
    private var isCopying = false

    init(
        makeCard: @escaping (String) -> TranslationViewModel = { TranslateAction.card(for: $0) },
        clipboard: ClipboardTransaction,
        permission: AccessibilityPermission = AccessibilityPermission(),
        panel: PanelController = PanelController(),
        isAvailable: @escaping () -> Bool = { AppCommand.translate.isAvailable },
        isSmartTypeFrontmost: @escaping () -> Bool = {
            NSWorkspace.shared.frontmostApplication?.processIdentifier == ProcessInfo.processInfo.processIdentifier
        },
        beep: @escaping () -> Void = { NSSound.beep() },
        explain: @escaping (Onboarding.Problem) -> Bool = { Onboarding.explain($0) }
    ) {
        self.makeCard = makeCard
        self.clipboard = clipboard
        self.permission = permission
        self.panel = panel
        self.isAvailable = isAvailable
        self.isSmartTypeFrontmost = isSmartTypeFrontmost
        self.beep = beep
        self.explain = explain
    }

    func translateSelection() async {
        guard isAvailable() else { return beep() }
        // A press while the selection is being copied, the hotkey's auto-repeat included.
        guard !isCopying else { return }
        // Fix Layout has the clipboard: borrowing it now would lose the person's own.
        guard !clipboard.isBorrowed else { return beep() }
        guard permission.isGranted else {
            Log.general.notice("Translate: no Accessibility permission")
            if explain(.accessibility) {
                permission.requestAccess()
            }
            return
        }
        // The panel would take the ⌘C meant for the app the person is in.
        panel.close()
        guard !isSmartTypeFrontmost() else { return beep() }

        isCopying = true
        let copied = await clipboard.run { await self.clipboard.copySelection() }
        isCopying = false
        guard let copied else {
            Log.general.notice("Translate: the clipboard may not be read")
            _ = explain(.pasteboard)
            return
        }
        guard let text = copied, !text.allSatisfy(\.isWhitespace) else {
            Log.general.notice("Translate: nothing selected")
            return beep()
        }
        await translate(text)
    }

    /// The Services door: macOS hands the text over, so nothing is copied and no permission is
    /// needed.
    func translateText(_ text: String) async {
        guard isAvailable(), !text.allSatisfy(\.isWhitespace) else { return beep() }
        await translate(text)
    }

    /// The core operation, which both doors share.
    func translate(_ text: String) async {
        let card = makeCard(text)
        panel.show(card)
        let start = ContinuousClock.now
        await card.translate()
        panel.fitToCard()
        Log.general.notice(
            "Translate: \(String(describing: card.state.problem), privacy: .public) after \(Int(start.duration(to: .now) / .milliseconds(1))) ms"
        )
    }

    /// The real card: Apple's engine, the person's macOS languages, and the picks made in
    /// Settings ▸ Translation.
    static func card(for text: String) -> TranslationViewModel {
        TranslationViewModel(
            original: text, translator: FallbackTranslator(engines: [AppleTranslationEngine()]),
            choices: TranslationChoices(),
            preferred: Locale.preferredLanguages.map { Locale.Language(identifier: $0) },
            copy: { text in
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            },
            openURL: { NSWorkspace.shared.open($0) })
    }
}

extension TranslationViewModel.State {
    /// For the log: the problem, or "translated", never the text.
    fileprivate var problem: String {
        switch self {
        case .translating: "still translating"
        case .translated: "translated"
        case .failed(let problem): "\(problem)"
        }
    }
}
