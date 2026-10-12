import AppKit
import OSLog
import SmartTypeEngines

/// Translate (⌃⌥⇧T by default): translates the selected text in a panel at the pointer. The
/// selection is read through Accessibility first; an app that does not say gets ⌘C, the same
/// way as for the layout fix, and the clipboard is given back.
final class TranslateAction {
    /// Where the selection came from, or why there is none.
    private enum Selection {
        case text(String)
        case nothingSelected
        case unreadableClipboard
        case clipboardBusy
    }

    private let makeCard: (String) -> TranslationViewModel
    private let clipboard: ClipboardTransaction
    private let permission: AccessibilityPermission
    private let panel: PanelController
    private let readSelection: () -> String?
    private let isAvailable: () -> Bool
    private let isSmartTypeFrontmost: () -> Bool
    private let beep: () -> Void
    private let explain: (Onboarding.Problem) -> Bool
    private var isReading = false

    init(
        makeCard: @escaping (String) -> TranslationViewModel = { TranslateAction.card(for: $0) },
        clipboard: ClipboardTransaction,
        permission: AccessibilityPermission,
        panel: PanelController = PanelController(),
        readSelection: @escaping () -> String? = { AXSelectionReader.read() },
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
        self.readSelection = readSelection
        self.isAvailable = isAvailable
        self.isSmartTypeFrontmost = isSmartTypeFrontmost
        self.beep = beep
        self.explain = explain
    }

    func translateSelection() async {
        guard isAvailable() else { return beep() }
        // A press while the selection is being read, the hotkey's auto-repeat included.
        guard !isReading else { return }
        guard permission.isGranted else {
            Log.general.notice("Translate: no Accessibility permission")
            if explain(.accessibility) {
                await permission.grantAccess()
            }
            return
        }
        // The panel would be the focused element, and would take the ⌘C meant for the app.
        panel.close()
        guard !isSmartTypeFrontmost() else { return beep() }

        isReading = true
        let selection = await readTheSelection()
        isReading = false
        switch selection {
        case .text(let text):
            await translate(text)
        case .nothingSelected:
            Log.general.notice("Translate: nothing selected")
            beep()
        case .unreadableClipboard:
            Log.general.notice("Translate: the clipboard may not be read")
            _ = explain(.pasteboard)
        case .clipboardBusy:
            beep()
        }
    }

    /// Accessibility first; ⌘C, with the clipboard borrowed, when the app does not say. An app
    /// that says nothing is selected gets no ⌘C: it would beep a second time, and VS Code would
    /// copy the whole line (measured: VS Code's empty answer is true).
    private func readTheSelection() async -> Selection {
        switch readSelection() {
        case let text? where !text.allSatisfy(\.isWhitespace):
            Log.general.notice("Translate: the selection read through Accessibility")
            return .text(text)
        case .some:
            return .nothingSelected
        case nil:
            break
        }
        // Fix Layout has the clipboard: borrowing it now would lose the person's own.
        guard !clipboard.isBorrowed else { return .clipboardBusy }
        guard let copied = await clipboard.run({ await self.clipboard.copySelection() }) else {
            return .unreadableClipboard
        }
        guard let text = copied, !text.allSatisfy(\.isWhitespace) else { return .nothingSelected }
        Log.general.notice("Translate: the selection copied with ⌘C")
        return .text(text)
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
