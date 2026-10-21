import AppKit
import Testing

@testable import SmartTypeApp
@testable import SmartTypeCore

/// The hotkey door: copy, fix, paste and switch the keyboard, and every guard before it.
@Suite struct LayoutFixActionTests {
    @Test func theSelectionIsRetypedAndTheLayoutSwitched() async {
        let app = FakeFrontApp()
        let outcome = ActionOutcome()
        app.selection = "ghbdtn"

        await LayoutFixAction.forTest(app.clipboard(), .trusted(), outcome).fixSelection()

        #expect(app.pasted == ["привет"])
        #expect(outcome.layouts == ["com.apple.keylayout.RussianWin"])
        #expect(outcome.beeps == 0)
    }

    /// The keyboard switches as the fixed text lands, not after the clipboard comes back.
    @Test func theLayoutSwitchesBeforeTheClipboardIsGivenBack() async {
        let app = FakeFrontApp()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        app.selection = "ghbdtn"
        let outcome = ActionOutcome()
        var onPasteboardAtSwitch: String?
        outcome.onSwitch = { onPasteboardAtSwitch = app.pasteboard.string(forType: .string) }

        await LayoutFixAction.forTest(app.clipboard(), .trusted(), outcome).fixSelection()

        #expect(onPasteboardAtSwitch == "привет")
        #expect(app.pasteboard.string(forType: .string) == "the person's clipboard")
    }

    @Test func withoutAccessibilityItExplainsAndPressesNothing() async {
        let app = FakeFrontApp()
        let macOS = PermissionRecorder()
        let outcome = ActionOutcome()
        app.selection = "ghbdtn"

        await LayoutFixAction.forTest(app.clipboard(), macOS, outcome).fixSelection()

        #expect(outcome.explained == [.accessibility])
        #expect(app.copies == 0)
        #expect(macOS.prompts == 0)
    }

    /// The alert's Grant Access does what the button in Settings does.
    @Test func agreeingToTheExplanationGrantsAccess() async {
        let macOS = PermissionRecorder()

        await LayoutFixAction.forTest(FakeFrontApp().clipboard(), macOS, agrees: true).fixSelection()

        #expect(macOS.commands.count == 1)
        #expect(macOS.relaunches == 1)
    }

    /// ⌘C would go to SmartType's own window, not to the text the person meant.
    @Test func inSmartTypesOwnWindowItOnlyBeeps() async {
        let app = FakeFrontApp()
        let outcome = ActionOutcome()
        app.selection = "ghbdtn"

        await LayoutFixAction.forTest(app.clipboard(), .trusted(), outcome, smartTypeIsFrontmost: true).fixSelection()

        #expect(outcome.beeps == 1)
        #expect(app.copies == 0)
    }

    /// One layout in macOS, or one left on: nothing to fix between, so no ⌘C either.
    @Test func withFewerThanTwoLayoutsItBeepsAndCopiesNothing() async {
        let app = FakeFrontApp()
        let outcome = ActionOutcome()
        app.selection = "ghbdtn"

        await LayoutFixAction.forTest(app.clipboard(), .trusted(), outcome, layouts: [.usQwerty]).fixSelection()

        #expect(outcome.beeps == 1)
        #expect(app.copies == 0)
    }

    @Test func withNothingSelectedItBeepsAndPastesNothing() async {
        let app = FakeFrontApp()
        let outcome = ActionOutcome()

        await LayoutFixAction.forTest(app.clipboard(), .trusted(), outcome).fixSelection()

        #expect(outcome.beeps == 1)
        #expect(app.pasted.isEmpty)
        #expect(outcome.layouts.isEmpty)
    }

    @Test func textWithNothingToFixIsLeftAsItIs() async {
        let app = FakeFrontApp()
        let outcome = ActionOutcome()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        app.selection = "2 + 2 = 4"

        await LayoutFixAction.forTest(app.clipboard(), .trusted(), outcome).fixSelection()

        #expect(outcome.beeps == 1)
        #expect(app.pasted.isEmpty)
        #expect(app.pasteboard.string(forType: .string) == "the person's clipboard")
    }

    @Test func aPasteboardSmartTypeMayNotReadIsExplained() async {
        let app = FakeFrontApp()
        let outcome = ActionOutcome()
        app.selection = "ghbdtn"

        await LayoutFixAction.forTest(app.clipboard(isDenied: true), .trusted(), outcome).fixSelection()

        #expect(outcome.explained == [.pasteboard])
        #expect(app.copies == 0)
    }
}
