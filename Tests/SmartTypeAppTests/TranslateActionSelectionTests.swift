import AppKit
import Testing

@testable import SmartTypeApp

/// Where the translation's text comes from besides ⌘C: macOS's Services, and what
/// Accessibility says is selected.
@Suite struct TranslateActionSelectionTests {
    init() {
        _ = NSApplication.shared
    }

    /// The Services door: macOS hands the text over, so nothing is copied, and no Accessibility
    /// is needed.
    @Test func textFromServicesIsTranslatedInThePanel() async {
        let app = FakeFrontApp()
        let panel = PanelController.forTest()

        await TranslateAction.forTest(app.clipboard(), PermissionRecorder(), panel: panel).translateText("Привет")

        #expect(panel.card?.original == "Привет")
        #expect(panel.card?.state == .translated("en: Привет", engine: "Fake"))
        #expect(app.copies == 0)
    }

    @Test(arguments: [(true, "  "), (false, "Привет")])
    func textFromServicesThatCannotBeTranslatedBeeps(_ isAvailable: Bool, _ text: String) async {
        let panel = PanelController.forTest()
        let outcome = ActionOutcome()

        await TranslateAction.forTest(
            FakeFrontApp().clipboard(), .trusted(), outcome, panel: panel, isAvailable: isAvailable
        ).translateText(text)

        #expect(outcome.beeps == 1)
        #expect(!panel.isShown)
    }

    /// Accessibility answers first: no ⌘C, so the clipboard is not borrowed at all and macOS
    /// asks nothing about pasting (ADR-006).
    @Test func aSelectionAccessibilityReadsIsTranslatedWithoutTheClipboard() async {
        let app = FakeFrontApp()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        let changeCount = app.pasteboard.changeCount
        let panel = PanelController.forTest()

        await TranslateAction.forTest(app.clipboard(), .trusted(), panel: panel, accessibilitySelection: "Привет")
            .translateSelection()

        #expect(panel.card?.original == "Привет")
        #expect(app.copies == 0)
        #expect(app.pasteboard.changeCount == changeCount)
    }

    /// An app that tells nothing through Accessibility still gets its ⌘C.
    @Test func withoutAnAnswerThroughAccessibilityTheSelectionIsCopied() async {
        let app = FakeFrontApp()
        app.selection = "Привет"
        let panel = PanelController.forTest()

        await TranslateAction.forTest(app.clipboard(), .trusted(), panel: panel, accessibilitySelection: nil)
            .translateSelection()

        #expect(app.copies == 1)
        #expect(panel.card?.original == "Привет")
    }

    /// An app that says nothing is selected gets no ⌘C: it would beep a second time, and VS Code
    /// would copy the whole line (measured: VS Code answers an empty selection truthfully).
    @Test(arguments: ["", "  \n"])
    func nothingSelectedThroughAccessibilityBeepsOnceAndCopiesNothing(_ answer: String) async {
        let app = FakeFrontApp()
        app.selection = "the whole line"
        let panel = PanelController.forTest()
        let outcome = ActionOutcome()

        await TranslateAction.forTest(
            app.clipboard(), .trusted(), outcome, panel: panel, accessibilitySelection: answer
        )
        .translateSelection()

        #expect(outcome.beeps == 1)
        #expect(app.copies == 0)
        #expect(!panel.isShown)
    }
}
