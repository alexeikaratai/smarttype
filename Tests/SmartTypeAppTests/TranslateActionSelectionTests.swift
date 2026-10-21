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
        let test = "\(#function)-\(isAvailable)"
        let panel = PanelController.forTest()
        let outcome = ActionOutcome()

        await TranslateAction.forTest(
            FakeFrontApp(test: test).clipboard(), .trusted(test: test), outcome, panel: panel, isAvailable: isAvailable,
            test: test
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
        let test = "\(#function)-\(answer.count)"
        let app = FakeFrontApp(test: test)
        app.selection = "the whole line"
        let panel = PanelController.forTest()
        let outcome = ActionOutcome()

        await TranslateAction.forTest(
            app.clipboard(), .trusted(test: test), outcome, panel: panel, accessibilitySelection: answer, test: test
        )
        .translateSelection()

        #expect(outcome.beeps == 1)
        #expect(app.copies == 0)
        #expect(!panel.isShown)
    }

    /// A press while the selection is being read, the hotkey's auto-repeat included, is
    /// swallowed: no beep for a clipboard the first press still has. With nothing selected the
    /// read keeps polling, which holds it there.
    @Test func aSecondPressWhileReadingIsIgnored() async {
        let app = FakeFrontApp()
        let gate = Gate()
        var isHeld = false
        let clipboard = app.clipboard(holding: { duration in
            guard duration == .milliseconds(10), !isHeld else { return }
            isHeld = true
            await gate.hold()
        })
        let outcome = ActionOutcome()
        let translation = TranslateAction.forTest(clipboard, .trusted(), outcome)

        let reading = Task { await translation.translateSelection() }
        #expect(await waitUntil { gate.isHolding })
        await translation.translateSelection()
        let beepsWhileReading = outcome.beeps
        gate.open()
        await reading.value

        #expect(beepsWhileReading == 0)
        #expect(app.copies == 1)
    }
}
