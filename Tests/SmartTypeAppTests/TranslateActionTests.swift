import AppKit
import Testing

@testable import SmartTypeApp
@testable import SmartTypeEngines

@Suite struct TranslateActionTests {
    init() {
        _ = NSApplication.shared
    }

    /// Everything the action did besides the keys and the panel.
    private final class Outcome {
        var beeps = 0
        var explained: [Onboarding.Problem] = []
    }

    private func action(
        _ app: FakeFrontApp, _ macOS: PermissionRecorder, _ panel: PanelController, _ outcome: Outcome,
        isAvailable: Bool = true, pasteboardDenied: Bool = false, smartTypeIsFrontmost: Bool = false,
        accessibilitySelection: String? = nil, agrees: Bool = false, test: String = #function
    ) -> TranslateAction {
        TranslateAction(
            makeCard: { text in
                TranslationViewModel(
                    original: text, translator: FallbackTranslator(engines: [FakeTranslationEngine()]),
                    choices: .forTest(test), preferred: [Locale.Language(identifier: "en-US")],
                    copy: { _ in }, openURL: { _ in })
            },
            clipboard: app.clipboard(isDenied: pasteboardDenied), permission: macOS.permission(), panel: panel,
            readSelection: { accessibilitySelection }, isAvailable: { isAvailable },
            isSmartTypeFrontmost: { smartTypeIsFrontmost },
            beep: { outcome.beeps += 1 },
            explain: { problem in
                outcome.explained.append(problem)
                return agrees
            })
    }

    private func trusted() -> PermissionRecorder {
        let macOS = PermissionRecorder()
        macOS.isTrusted = true
        return macOS
    }

    private func panel() -> PanelController {
        PanelController(present: { _ in }, pointer: { .zero }, visibleFrame: { _ in .zero }, watchClicks: { _ in {} })
    }

    @Test func theSelectionIsTranslatedInThePanelAndTheClipboardGivenBack() async {
        let app = FakeFrontApp()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        app.selection = "Привет, как дела?"
        let panel = panel()

        await action(app, trusted(), panel, Outcome()).translateSelection()

        #expect(panel.card?.original == "Привет, как дела?")
        #expect(panel.card?.state == .translated("en: Привет, как дела?", engine: "Fake"))
        #expect(app.pasteboard.string(forType: .string) == "the person's clipboard")
    }

    /// The panel opens while the engine works and takes the translation's height once it is in.
    @Test func thePanelFitsTheTranslation() async throws {
        let app = FakeFrontApp()
        app.selection = String(repeating: "Привет, как дела? ", count: 12)
        var presented: NSPanel?
        var heightWhileTranslating: CGFloat = 0
        let panel = PanelController(
            present: {
                presented = $0
                heightWhileTranslating = $0.frame.height
            }, pointer: { .zero }, visibleFrame: { _ in .zero }, watchClicks: { _ in {} })

        await action(app, trusted(), panel, Outcome()).translateSelection()

        let shown = try #require(presented)
        #expect(shown.frame.height > heightWhileTranslating)
    }

    /// Its own panel would catch the ⌘C meant for the app, so the panel closes first.
    @Test func anOpenPanelClosesBeforeTheCopy() async {
        let app = FakeFrontApp()
        app.selection = "Привет"
        let panel = panel()
        let fix = action(app, trusted(), panel, Outcome())
        await fix.translateSelection()
        var panelWasShownAtCopy: Bool?
        app.onCopy = { panelWasShownAtCopy = panel.isShown }

        await fix.translateSelection()

        #expect(panelWasShownAtCopy == false)
        #expect(panel.isShown)
    }

    @Test func withNothingSelectedItBeepsAndShowsNothing() async {
        let panel = panel()
        let outcome = Outcome()

        await action(FakeFrontApp(), trusted(), panel, outcome).translateSelection()

        #expect(outcome.beeps == 1)
        #expect(!panel.isShown)
    }

    /// Spaces or line breaks alone are nothing to translate.
    @Test func aBlankSelectionBeepsAndShowsNothing() async {
        let app = FakeFrontApp()
        app.selection = "  \n "
        let panel = panel()
        let outcome = Outcome()

        await action(app, trusted(), panel, outcome).translateSelection()

        #expect(outcome.beeps == 1)
        #expect(!panel.isShown)
    }

    @Test func beforeMacOS26ItOnlyBeeps() async {
        let app = FakeFrontApp()
        app.selection = "Привет"
        let outcome = Outcome()

        await action(app, trusted(), panel(), outcome, isAvailable: false).translateSelection()

        #expect(outcome.beeps == 1)
        #expect(app.copies == 0)
    }

    @Test func withoutAccessibilityItExplainsAndCopiesNothing() async {
        let app = FakeFrontApp()
        app.selection = "Привет"
        let outcome = Outcome()

        await action(app, PermissionRecorder(), panel(), outcome).translateSelection()

        #expect(outcome.explained == [.accessibility])
        #expect(app.copies == 0)
    }

    /// The alert's Grant Access does what the button in Settings does.
    @Test func agreeingToTheExplanationGrantsAccess() async {
        let macOS = PermissionRecorder()

        await action(FakeFrontApp(), macOS, panel(), Outcome(), agrees: true).translateSelection()

        #expect(macOS.commands.count == 1)
        #expect(macOS.relaunches == 1)
    }

    @Test func aPasteboardSmartTypeMayNotReadIsExplained() async {
        let app = FakeFrontApp()
        app.selection = "Привет"
        let outcome = Outcome()

        await action(app, trusted(), panel(), outcome, pasteboardDenied: true).translateSelection()

        #expect(outcome.explained == [.pasteboard])
        #expect(app.copies == 0)
    }

    @Test func inSmartTypesOwnWindowItOnlyBeeps() async {
        let app = FakeFrontApp()
        app.selection = "Привет"
        let outcome = Outcome()

        await action(app, trusted(), panel(), outcome, smartTypeIsFrontmost: true).translateSelection()

        #expect(outcome.beeps == 1)
        #expect(app.copies == 0)
    }

    /// The Services door: macOS hands the text over, so nothing is copied, and no Accessibility
    /// is needed.
    @Test func textFromServicesIsTranslatedInThePanel() async {
        let app = FakeFrontApp()
        let panel = panel()

        await action(app, PermissionRecorder(), panel, Outcome()).translateText("Привет")

        #expect(panel.card?.original == "Привет")
        #expect(panel.card?.state == .translated("en: Привет", engine: "Fake"))
        #expect(app.copies == 0)
    }

    @Test(arguments: [(true, "  "), (false, "Привет")])
    func textFromServicesThatCannotBeTranslatedBeeps(_ isAvailable: Bool, _ text: String) async {
        let panel = panel()
        let outcome = Outcome()

        await action(FakeFrontApp(), trusted(), panel, outcome, isAvailable: isAvailable).translateText(text)

        #expect(outcome.beeps == 1)
        #expect(!panel.isShown)
    }

    /// Accessibility answers first: no ⌘C, so the clipboard is not borrowed at all and macOS
    /// asks nothing about pasting (ADR-006).
    @Test func aSelectionAccessibilityReadsIsTranslatedWithoutTheClipboard() async {
        let app = FakeFrontApp()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        let changeCount = app.pasteboard.changeCount
        let panel = panel()

        await action(app, trusted(), panel, Outcome(), accessibilitySelection: "Привет").translateSelection()

        #expect(panel.card?.original == "Привет")
        #expect(app.copies == 0)
        #expect(app.pasteboard.changeCount == changeCount)
    }

    /// An app that tells nothing, or only blanks, through Accessibility still gets its ⌘C.
    @Test(arguments: [String?.none, "  \n"])
    func withoutAnAnswerThroughAccessibilityTheSelectionIsCopied(_ answer: String?) async {
        let app = FakeFrontApp()
        app.selection = "Привет"
        let panel = panel()

        await action(app, trusted(), panel, Outcome(), accessibilitySelection: answer).translateSelection()

        #expect(app.copies == 1)
        #expect(panel.card?.original == "Привет")
    }
}
