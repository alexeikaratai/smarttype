import AppKit
import Testing

@testable import SmartTypeApp

/// Where the fix's text comes from besides ⌘C: macOS's Services, and what Accessibility says
/// is selected.
@Suite struct LayoutFixActionSelectionTests {
    /// The Services door: macOS hands the text over and puts the result in place, so the
    /// clipboard and the keys are never touched. The keyboard still switches.
    @Test func textFromServicesIsFixedWithoutTheClipboard() {
        let app = FakeFrontApp()
        let outcome = ActionOutcome()

        let fixed = LayoutFixAction.forTest(app.clipboard(), .trusted(), outcome).fixInPlace("ghbdtn")

        #expect(fixed == "привет")
        #expect(outcome.layouts == ["com.apple.keylayout.RussianWin"])
        #expect(app.copies == 0)
        #expect(app.pasted.isEmpty)
    }

    @Test func textFromServicesWithNothingToFixBeeps() {
        let outcome = ActionOutcome()

        let fixed = LayoutFixAction.forTest(FakeFrontApp().clipboard(), .trusted(), outcome).fixInPlace("2 + 2 = 4")

        #expect(fixed == nil)
        #expect(outcome.beeps == 1)
        #expect(outcome.layouts.isEmpty)
    }

    /// No Accessibility needed: the Services door copies and pastes nothing.
    @Test func textFromServicesNeedsNoPermission() {
        let outcome = ActionOutcome()

        let fixed = LayoutFixAction.forTest(FakeFrontApp().clipboard(), PermissionRecorder(), outcome)
            .fixInPlace("ghbdtn")

        #expect(fixed == "привет")
        #expect(outcome.explained.isEmpty)
    }

    /// With nothing selected VS Code's ⌘C copies the whole line, and the fix would retype it. An
    /// app that says through Accessibility that nothing is selected gets no ⌘C at all.
    @Test func nothingSelectedThroughAccessibilityBeepsAndCopiesNothing() async {
        let app = FakeFrontApp()
        app.selection = "ghbdtn"
        let outcome = ActionOutcome()

        await LayoutFixAction.forTest(app.clipboard(), .trusted(), outcome, accessibilitySelection: "").fixSelection()

        #expect(outcome.beeps == 1)
        #expect(app.copies == 0)
        #expect(app.pasted.isEmpty)
    }

    /// What Accessibility says may be stale, so the fix still copies what it replaces.
    @Test func aSelectionThroughAccessibilityIsStillCopied() async {
        let app = FakeFrontApp()
        app.selection = "ghbdtn"

        await LayoutFixAction.forTest(app.clipboard(), .trusted(), accessibilitySelection: "something else")
            .fixSelection()

        #expect(app.copies == 1)
        #expect(app.pasted == ["привет"])
    }
}
