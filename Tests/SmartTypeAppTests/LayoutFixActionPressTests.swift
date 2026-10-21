import AppKit
import Testing

@testable import SmartTypeApp
@testable import SmartTypeEngines

/// Pressing Fix Layout again, with the translation panel open, or with keys still held.
@Suite struct LayoutFixActionPressTests {
    init() {
        _ = NSApplication.shared
    }

    /// A press while a fix is running, the hotkey's auto-repeat included, is swallowed without
    /// a beep.
    @Test func aSecondPressWhileFixingIsIgnored() async {
        let app = FakeFrontApp()
        app.selection = "ghbdtn"
        let outcome = ActionOutcome()
        let fix = LayoutFixAction.forTest(app.clipboard(yielding: true), .trusted(), outcome)

        let first = Task { await fix.fixSelection() }
        let second = Task { await fix.fixSelection() }
        await first.value
        await second.value

        #expect(app.copies == 1)
        #expect(app.pasted == ["привет"])
        #expect(outcome.beeps == 0)
    }

    /// One fix done, the next press fixes again: the app keeps one action for its whole life.
    @Test func aFixRunsAgainOnceTheLastOneIsDone() async {
        let app = FakeFrontApp()
        app.selection = "ghbdtn"
        let fix = LayoutFixAction.forTest(app.clipboard(), .trusted())

        await fix.fixSelection()
        await fix.fixSelection()

        #expect(app.pasted == ["привет", "привет"])
    }

    /// The panel takes the keys while it is up, without SmartType in front: it is closed before
    /// the ⌘C, which would go to the panel otherwise.
    @Test func anOpenPanelClosesBeforeTheCopy() async {
        let app = FakeFrontApp()
        app.selection = "ghbdtn"
        let panel = PanelController.forTest()
        panel.show(
            TranslationViewModel(
                original: "Привет", translator: FallbackTranslator(engines: [FakeTranslationEngine()]),
                choices: .forTest(#function), copy: { _ in }, openURL: { _ in }))
        var isShownAtCopy: Bool?
        app.onCopy = { isShownAtCopy = panel.isShown }

        await LayoutFixAction.forTest(app.clipboard(), .trusted(), panel: panel).fixSelection()

        #expect(isShownAtCopy == false)
        #expect(app.pasted == ["привет"])
    }

    /// The keyboard switches once the keys are up and before ⌘V, so ⌘V goes on its key in the
    /// layout the app reads it in: Dvorak and Turkish F type it on other keys than U.S. does.
    @Test func theLayoutSwitchesRightBeforeThePaste() async {
        let app = FakeFrontApp()
        app.selection = "ghbdtn"
        let outcome = ActionOutcome()
        var pastesAtSwitch: Int?
        outcome.onSwitch = { pastesAtSwitch = app.pasted.count }

        await LayoutFixAction.forTest(app.clipboard(), .trusted(), outcome).fixSelection()

        #expect(pastesAtSwitch == 0)
        #expect(app.pasted == ["привет"])
    }

    /// Keys held for a second after the copy: ⌘V never went out, so the text is as it was. A
    /// beep says so, the keyboard stays, and the clipboard comes back.
    @Test func aPasteThatNeverWentOutBeepsAndKeepsTheKeyboard() async {
        let app = FakeFrontApp()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        app.selection = "ghbdtn"
        let outcome = ActionOutcome()
        let clipboard = app.clipboard(currentModifiers: { app.copies > 0 ? .maskShift : [] })

        await LayoutFixAction.forTest(clipboard, .trusted(), outcome).fixSelection()

        #expect(app.pasted.isEmpty)
        #expect(outcome.beeps == 1)
        #expect(outcome.layouts.isEmpty)
        #expect(app.pasteboard.string(forType: .string) == "the person's clipboard")
    }
}
