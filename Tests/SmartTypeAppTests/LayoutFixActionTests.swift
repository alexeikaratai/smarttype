import AppKit
import Testing

@testable import SmartTypeApp
@testable import SmartTypeCore

@Suite struct LayoutFixActionTests {
    /// Everything the action did besides the keys.
    private final class Outcome {
        var beeps = 0
        var explained: [Onboarding.Problem] = []
        var layouts: [String] = []
    }

    private func action(
        _ app: FakeFrontApp, _ macOS: PermissionRecorder, _ outcome: Outcome,
        smartTypeIsFrontmost: Bool = false, pasteboardDenied: Bool = false, agrees: Bool = false,
        yielding: Bool = false
    ) -> LayoutFixAction {
        LayoutFixAction(
            corrector: LayoutCorrector(
                layouts: BuiltInLayouts().layouts, detector: LanguageDetector(scorers: [PhonotacticScorer()])),
            clipboard: app.clipboard(isDenied: pasteboardDenied, yielding: yielding),
            permission: macOS.permission(),
            selectLayout: { layoutID in
                outcome.layouts.append(layoutID)
                return true
            },
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

    @Test func theSelectionIsRetypedAndTheLayoutSwitched() async {
        let app = FakeFrontApp()
        let outcome = Outcome()
        app.selection = "ghbdtn"

        await action(app, trusted(), outcome).fixSelection()

        #expect(app.pasted == ["привет"])
        #expect(outcome.layouts == ["com.apple.keylayout.RussianWin"])
        #expect(outcome.beeps == 0)
    }

    /// The keyboard switches as the fixed text lands, not after the clipboard comes back.
    @Test func theLayoutSwitchesBeforeTheClipboardIsGivenBack() async {
        let app = FakeFrontApp()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        app.selection = "ghbdtn"
        var onPasteboardAtSwitch: String?
        let fix = LayoutFixAction(
            corrector: LayoutCorrector(
                layouts: BuiltInLayouts().layouts, detector: LanguageDetector(scorers: [PhonotacticScorer()])),
            clipboard: app.clipboard(),
            permission: trusted().permission(),
            selectLayout: { _ in
                onPasteboardAtSwitch = app.pasteboard.string(forType: .string)
                return true
            },
            isSmartTypeFrontmost: { false }, beep: {}, explain: { _ in false })

        await fix.fixSelection()

        #expect(onPasteboardAtSwitch == "привет")
        #expect(app.pasteboard.string(forType: .string) == "the person's clipboard")
    }

    @Test func withoutAccessibilityItExplainsAndPressesNothing() async {
        let app = FakeFrontApp()
        let macOS = PermissionRecorder()
        let outcome = Outcome()
        app.selection = "ghbdtn"

        await action(app, macOS, outcome).fixSelection()

        #expect(outcome.explained == [.accessibility])
        #expect(app.copies == 0)
        #expect(macOS.prompts == 0)
    }

    /// The alert's Grant Access does what the button in Settings does.
    @Test func agreeingToTheExplanationGrantsAccess() async {
        let macOS = PermissionRecorder()

        await action(FakeFrontApp(), macOS, Outcome(), agrees: true).fixSelection()

        #expect(macOS.commands.count == 1)
        #expect(macOS.relaunches == 1)
    }

    /// ⌘C would go to SmartType's own window, not to the text the person meant.
    @Test func inSmartTypesOwnWindowItOnlyBeeps() async {
        let app = FakeFrontApp()
        let outcome = Outcome()
        app.selection = "ghbdtn"

        await action(app, trusted(), outcome, smartTypeIsFrontmost: true).fixSelection()

        #expect(outcome.beeps == 1)
        #expect(app.copies == 0)
    }

    @Test func withNothingSelectedItBeepsAndPastesNothing() async {
        let app = FakeFrontApp()
        let outcome = Outcome()

        await action(app, trusted(), outcome).fixSelection()

        #expect(outcome.beeps == 1)
        #expect(app.pasted.isEmpty)
        #expect(outcome.layouts.isEmpty)
    }

    @Test func textWithNothingToFixIsLeftAsItIs() async {
        let app = FakeFrontApp()
        let outcome = Outcome()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        app.selection = "2 + 2 = 4"

        await action(app, trusted(), outcome).fixSelection()

        #expect(outcome.beeps == 1)
        #expect(app.pasted.isEmpty)
        #expect(app.pasteboard.string(forType: .string) == "the person's clipboard")
    }

    @Test func aPasteboardSmartTypeMayNotReadIsExplained() async {
        let app = FakeFrontApp()
        let outcome = Outcome()
        app.selection = "ghbdtn"

        await action(app, trusted(), outcome, pasteboardDenied: true).fixSelection()

        #expect(outcome.explained == [.pasteboard])
        #expect(app.copies == 0)
    }

    /// A press while a fix is running, the hotkey's auto-repeat included, is swallowed.
    @Test func aSecondPressWhileFixingIsIgnored() async {
        let app = FakeFrontApp()
        app.selection = "ghbdtn"
        let fix = action(app, trusted(), Outcome(), yielding: true)

        let first = Task { await fix.fixSelection() }
        let second = Task { await fix.fixSelection() }
        await first.value
        await second.value

        #expect(app.copies == 1)
        #expect(app.pasted == ["привет"])
    }

    /// The Services door: macOS hands the text over and puts the result in place, so the
    /// clipboard and the keys are never touched. The keyboard still switches.
    @Test func textFromServicesIsFixedWithoutTheClipboard() {
        let app = FakeFrontApp()
        let outcome = Outcome()

        let fixed = action(app, trusted(), outcome).fixInPlace("ghbdtn")

        #expect(fixed == "привет")
        #expect(outcome.layouts == ["com.apple.keylayout.RussianWin"])
        #expect(app.copies == 0)
        #expect(app.pasted.isEmpty)
    }

    @Test func textFromServicesWithNothingToFixBeeps() {
        let outcome = Outcome()

        let fixed = action(FakeFrontApp(), trusted(), outcome).fixInPlace("2 + 2 = 4")

        #expect(fixed == nil)
        #expect(outcome.beeps == 1)
        #expect(outcome.layouts.isEmpty)
    }

    /// No Accessibility needed: the Services door copies and pastes nothing.
    @Test func textFromServicesNeedsNoPermission() {
        let outcome = Outcome()

        let fixed = action(FakeFrontApp(), PermissionRecorder(), outcome).fixInPlace("ghbdtn")

        #expect(fixed == "привет")
        #expect(outcome.explained.isEmpty)
    }
}
