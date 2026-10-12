import AppKit
import Testing

@testable import SmartTypeApp
@testable import SmartTypeCore
@testable import SmartTypeEngines

@Suite struct SharedClipboardTests {
    init() {
        _ = NSApplication.shared
    }

    private func trusted() -> AccessibilityPermission {
        let macOS = PermissionRecorder()
        macOS.isTrusted = true
        return macOS.permission()
    }

    private func fix(_ clipboard: ClipboardTransaction, beep: @escaping () -> Void = {}) -> LayoutFixAction {
        LayoutFixAction(
            corrector: LayoutCorrector(
                layouts: BuiltInLayouts().layouts, detector: LanguageDetector(scorers: [PhonotacticScorer()])),
            clipboard: clipboard, permission: trusted(), selectLayout: { _ in true }, isSmartTypeFrontmost: { false },
            beep: beep, explain: { _ in false })
    }

    private func translate(
        _ clipboard: ClipboardTransaction, beep: @escaping () -> Void = {}, accessibilitySelection: String? = nil,
        test: String = #function
    ) -> TranslateAction {
        TranslateAction(
            makeCard: { text in
                TranslationViewModel(
                    original: text, translator: FallbackTranslator(engines: [FakeTranslationEngine()]),
                    choices: .forTest(test), preferred: [Locale.Language(identifier: "en")], copy: { _ in },
                    openURL: { _ in })
            },
            clipboard: clipboard, permission: trusted(),
            panel: PanelController(
                present: { _ in }, pointer: { .zero }, visibleFrame: { _ in .zero }, watchClicks: { _ in {} }),
            readSelection: { accessibilitySelection }, isAvailable: { true }, isSmartTypeFrontmost: { false },
            beep: beep, explain: { _ in false })
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
        var beeps = 0
        let translation = translate(clipboard, beep: { beeps += 1 })

        let fixing = Task { await fix(clipboard).fixSelection() }
        #expect(await waitUntil { gate.isHolding })
        let copies = app.copies
        await translation.translateSelection()
        gate.open()
        await fixing.value

        #expect(beeps == 1)
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
        var beeps = 0
        let fixing = fix(clipboard, beep: { beeps += 1 })

        let translating = Task { await translate(clipboard).translateSelection() }
        #expect(await waitUntil { gate.isHolding })
        let copies = app.copies
        await fixing.fixSelection()
        gate.open()
        await translating.value

        #expect(beeps == 1)
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
        var beeps = 0
        let translation = translate(clipboard, beep: { beeps += 1 }, accessibilitySelection: "Привет")

        let fixing = Task { await fix(clipboard).fixSelection() }
        #expect(await waitUntil { gate.isHolding })
        let copies = app.copies
        await translation.translateSelection()
        gate.open()
        await fixing.value

        #expect(beeps == 0)
        #expect(app.copies == copies)
        #expect(app.pasteboard.string(forType: .string) == "the person's clipboard")
    }
}
