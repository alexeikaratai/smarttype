import AppKit
import Testing

@testable import SmartTypeApp

/// The hotkey door: copy, translate in the panel, give the clipboard back, and every guard
/// before it.
@Suite struct TranslateActionTests {
    init() {
        _ = NSApplication.shared
    }

    @Test func theSelectionIsTranslatedInThePanelAndTheClipboardGivenBack() async {
        let app = FakeFrontApp()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        app.selection = "Привет, как дела?"
        let panel = PanelController.forTest()

        await TranslateAction.forTest(app.clipboard(), .trusted(), panel: panel).translateSelection()

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

        await TranslateAction.forTest(app.clipboard(), .trusted(), panel: panel).translateSelection()

        let shown = try #require(presented)
        #expect(shown.frame.height > heightWhileTranslating)
    }

    /// Its own panel would catch the ⌘C meant for the app, so the panel closes first.
    @Test func anOpenPanelClosesBeforeTheCopy() async {
        let app = FakeFrontApp()
        app.selection = "Привет"
        let panel = PanelController.forTest()
        let translation = TranslateAction.forTest(app.clipboard(), .trusted(), panel: panel)
        await translation.translateSelection()
        var panelWasShownAtCopy: Bool?
        app.onCopy = { panelWasShownAtCopy = panel.isShown }

        await translation.translateSelection()

        #expect(panelWasShownAtCopy == false)
        #expect(panel.isShown)
    }

    @Test func withNothingSelectedItBeepsAndShowsNothing() async {
        let panel = PanelController.forTest()
        let outcome = ActionOutcome()

        await TranslateAction.forTest(FakeFrontApp().clipboard(), .trusted(), outcome, panel: panel)
            .translateSelection()

        #expect(outcome.beeps == 1)
        #expect(!panel.isShown)
    }

    /// Spaces or line breaks alone are nothing to translate.
    @Test func aBlankSelectionBeepsAndShowsNothing() async {
        let app = FakeFrontApp()
        app.selection = "  \n "
        let panel = PanelController.forTest()
        let outcome = ActionOutcome()

        await TranslateAction.forTest(app.clipboard(), .trusted(), outcome, panel: panel).translateSelection()

        #expect(outcome.beeps == 1)
        #expect(!panel.isShown)
    }

    @Test func beforeMacOS26ItOnlyBeeps() async {
        let app = FakeFrontApp()
        app.selection = "Привет"
        let outcome = ActionOutcome()

        await TranslateAction.forTest(app.clipboard(), .trusted(), outcome, isAvailable: false).translateSelection()

        #expect(outcome.beeps == 1)
        #expect(app.copies == 0)
    }

    @Test func withoutAccessibilityItExplainsAndCopiesNothing() async {
        let app = FakeFrontApp()
        app.selection = "Привет"
        let outcome = ActionOutcome()

        await TranslateAction.forTest(app.clipboard(), PermissionRecorder(), outcome).translateSelection()

        #expect(outcome.explained == [.accessibility])
        #expect(app.copies == 0)
    }

    /// The alert's Grant Access does what the button in Settings does.
    @Test func agreeingToTheExplanationGrantsAccess() async {
        let macOS = PermissionRecorder()

        await TranslateAction.forTest(FakeFrontApp().clipboard(), macOS, agrees: true).translateSelection()

        #expect(macOS.commands.count == 1)
        #expect(macOS.relaunches == 1)
    }

    @Test func aPasteboardSmartTypeMayNotReadIsExplained() async {
        let app = FakeFrontApp()
        app.selection = "Привет"
        let outcome = ActionOutcome()

        await TranslateAction.forTest(app.clipboard(isDenied: true), .trusted(), outcome).translateSelection()

        #expect(outcome.explained == [.pasteboard])
        #expect(app.copies == 0)
    }

    @Test func inSmartTypesOwnWindowItOnlyBeeps() async {
        let app = FakeFrontApp()
        app.selection = "Привет"
        let outcome = ActionOutcome()

        await TranslateAction.forTest(app.clipboard(), .trusted(), outcome, smartTypeIsFrontmost: true)
            .translateSelection()

        #expect(outcome.beeps == 1)
        #expect(app.copies == 0)
    }
}
