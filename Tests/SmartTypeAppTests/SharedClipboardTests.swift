import AppKit
import Testing

@testable import SmartTypeApp

@Suite struct SharedClipboardTests {
    init() {
        _ = NSApplication.shared
    }

    /// Translate pressed while a fix waits to give the clipboard back would snapshot the text
    /// SmartType just pasted, give that back, and leave the fix unable to restore the person's
    /// own clipboard. Both commands share one transaction: the second one beeps instead, and
    /// works again once the clipboard is back.
    @Test func translateWaitsUntilAFixHasGivenTheClipboardBack() async {
        let app = FakeFrontApp()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        app.selection = "ghbdtn"
        let gate = Gate()
        let clipboard = app.clipboard(holding: { if $0 == .milliseconds(250) { await gate.hold() } })
        let outcome = ActionOutcome()
        let translation = TranslateAction.forTest(clipboard, .trusted(), outcome)

        let fixing = Task { await LayoutFixAction.forTest(clipboard, .trusted()).fixSelection() }
        #expect(await waitUntil { gate.isHolding })
        let copies = app.copies
        await translation.translateSelection()
        gate.open()
        await fixing.value

        #expect(outcome.beeps == 1)
        #expect(app.copies == copies)
        #expect(app.pasteboard.string(forType: .string) == "the person's clipboard")
        await translation.translateSelection()
        #expect(app.copies == copies + 1)
    }

    /// The other way round: a fix pressed while Translate is still waiting for its copy beeps
    /// and copies nothing. With nothing selected, Translate keeps polling, which holds it there.
    @Test func aFixWaitsWhileTranslateCopies() async {
        let app = FakeFrontApp()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        let gate = Gate()
        var isHeld = false
        let clipboard = app.clipboard(holding: { duration in
            guard duration == .milliseconds(10), !isHeld else { return }
            isHeld = true
            await gate.hold()
        })
        let outcome = ActionOutcome()
        let fixing = LayoutFixAction.forTest(clipboard, .trusted(), outcome)

        let translating = Task { await TranslateAction.forTest(clipboard, .trusted()).translateSelection() }
        #expect(await waitUntil { gate.isHolding })
        let copies = app.copies
        await fixing.fixSelection()
        gate.open()
        await translating.value

        #expect(outcome.beeps == 1)
        #expect(app.copies == copies)
        #expect(app.pasteboard.string(forType: .string) == "the person's clipboard")
    }

    /// Read through Accessibility, a translation needs no clipboard, so a fix holding it does
    /// not stand in the way.
    @Test func translateReadThroughAccessibilityDoesNotWaitForTheClipboard() async {
        let app = FakeFrontApp()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        app.selection = "ghbdtn"
        let gate = Gate()
        let clipboard = app.clipboard(holding: { if $0 == .milliseconds(250) { await gate.hold() } })
        let outcome = ActionOutcome()
        let translation = TranslateAction.forTest(clipboard, .trusted(), outcome, accessibilitySelection: "Привет")

        let fixing = Task { await LayoutFixAction.forTest(clipboard, .trusted()).fixSelection() }
        #expect(await waitUntil { gate.isHolding })
        let copies = app.copies
        await translation.translateSelection()
        gate.open()
        await fixing.value

        #expect(outcome.beeps == 0)
        #expect(app.copies == copies)
        #expect(app.pasteboard.string(forType: .string) == "the person's clipboard")
    }
}
