import AppKit
import Testing

@testable import SmartTypeApp

/// An app that answers ⌘C after half a second, a virtual machine or a remote desktop: its copy
/// would land on the person's clipboard after SmartType gave it back.
@Suite struct ClipboardLateCopyTests {
    /// The copy lands while SmartType still watches: the person's own clipboard comes back.
    @Test func aCopyThatLandsLateIsGivenBack() async {
        let app = FakeFrontApp()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        let gate = Gate()
        let clipboard = app.clipboard(holding: { if $0 == .milliseconds(50) { await gate.hold() } })

        let copied = try? await clipboard.run { await clipboard.copySelection() }
        #expect(await waitUntil { gate.isHolding })
        app.pasteboard.clearContents()
        app.pasteboard.setString("ghbdtn", forType: .string)
        gate.open()

        #expect(copied == nil)
        #expect(await waitUntil { app.pasteboard.string(forType: .string) == "the person's clipboard" })
    }

    /// While it watches, the clipboard is still lent: the other command beeps instead of taking
    /// it, and gets it once the watch is over.
    @Test func theClipboardStaysLentWhileALateCopyMayLand() async {
        let app = FakeFrontApp()
        let gate = Gate()
        var isHeld = false
        let clipboard = app.clipboard(holding: { duration in
            guard duration == .milliseconds(50), !isHeld else { return }
            isHeld = true
            await gate.hold()
        })

        _ = try? await clipboard.run { await clipboard.copySelection() }
        #expect(await waitUntil { gate.isHolding })

        await #expect(throws: ClipboardTransaction.Refusal.busy) { try await clipboard.run {} }
        gate.open()
        #expect(await isLentAgain(clipboard))
    }

    /// Nothing landed: the clipboard is left as it was, and lent again.
    @Test func withoutALateCopyNothingIsWritten() async {
        let app = FakeFrontApp()
        app.pasteboard.setString("the person's clipboard", forType: .string)
        let before = app.pasteboard.changeCount
        let clipboard = app.clipboard()

        _ = try? await clipboard.run { await clipboard.copySelection() }

        #expect(await isLentAgain(clipboard))
        #expect(app.pasteboard.changeCount == before)
    }

    private func isLentAgain(_ clipboard: ClipboardTransaction) async -> Bool {
        for _ in 0..<200 {
            if (try? await clipboard.run {}) != nil {
                return true
            }
            await Task.yield()
        }
        return false
    }
}
