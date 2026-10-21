import AppKit
import Testing

@testable import SmartTypeApp

/// When the pasteboard is not lent at all: SmartType may not read it, or it is already lent.
@Suite struct ClipboardRefusalTests {
    /// Paste from Other Apps set to Deny: ⌘C would overwrite a clipboard SmartType could not
    /// put back, so nothing is pressed at all.
    @Test func aPasteboardSmartTypeMayNotReadIsNotBorrowed() async {
        let app = FakeFrontApp()
        app.selection = "ghbdtn"
        let clipboard = app.clipboard(isDenied: true)

        await #expect(throws: ClipboardTransaction.Refusal.mayNotRead) {
            try await clipboard.run { _ = await clipboard.copySelection() }
        }
        #expect(app.copies == 0)
    }

    /// Lent twice, the second snapshot would be of SmartType's own paste, and giving that back
    /// would lose the person's clipboard: the transaction itself refuses, whoever asks.
    @Test func aBorrowedPasteboardIsNotLentAgain() async throws {
        let app = FakeFrontApp()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        let clipboard = app.clipboard()
        var refusal: ClipboardTransaction.Refusal?

        try await clipboard.run {
            await clipboard.paste("привет")
            do throws(ClipboardTransaction.Refusal) {
                try await clipboard.run { await clipboard.paste("again") }
            } catch {
                refusal = error
            }
        }

        #expect(refusal == .busy)
        #expect(app.pasted == ["привет"])
        #expect(app.pasteboard.string(forType: .string) == "the person's clipboard")
    }
}
