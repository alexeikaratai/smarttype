import AppKit
import Testing

@testable import SmartTypeApp

@Suite struct TextServiceProviderTests {
    /// The pasteboard macOS hands a service: a private one here, never the person's clipboard.
    private func pasteboard(_ text: String?, test: String = #function) -> NSPasteboard {
        let pasteboard = NSPasteboard(name: .init("com.smarttype.tests.services.\(test)"))
        pasteboard.clearContents()
        if let text {
            pasteboard.setString(text, forType: .string)
        }
        return pasteboard
    }

    @Test func theFixedTextGoesBackToReplaceTheSelection() {
        let selection = pasteboard("ghbdtn")
        let provider = TextServiceProvider(fixInPlace: { $0 == "ghbdtn" ? "привет" : nil }, translateText: { _ in })
        var error: NSString?

        provider.fixLayout(selection, userData: "", error: &error)

        #expect(selection.string(forType: .string) == "привет")
        #expect(error == nil)
    }

    /// Nothing written back leaves the selection as it was.
    @Test func textThatNeedsNoFixIsLeftAlone() {
        let selection = pasteboard("привет")
        let provider = TextServiceProvider(fixInPlace: { _ in nil }, translateText: { _ in })
        let changeCount = selection.changeCount
        var error: NSString?

        provider.fixLayout(selection, userData: "", error: &error)

        #expect(selection.changeCount == changeCount)
        #expect(selection.string(forType: .string) == "привет")
    }

    /// Services answer at once: the translation is started, and shows in the panel.
    @Test func translateHandsTheTextOver() {
        var translated: [String] = []
        let provider = TextServiceProvider(fixInPlace: { _ in nil }, translateText: { translated.append($0) })
        var error: NSString?

        provider.translate(pasteboard("Привет"), userData: "", error: &error)

        #expect(translated == ["Привет"])
    }

    @Test func aPasteboardWithoutTextAsksForNothing() {
        var asked = 0
        let provider = TextServiceProvider(
            fixInPlace: { _ in
                asked += 1
                return nil
            },
            translateText: { _ in asked += 1 })
        var error: NSString?

        provider.fixLayout(pasteboard(nil), userData: "", error: &error)
        provider.translate(pasteboard(nil, test: "second"), userData: "", error: &error)

        #expect(asked == 0)
    }
}
