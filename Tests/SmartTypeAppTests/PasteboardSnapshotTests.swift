import AppKit
import Testing

@testable import SmartTypeApp

@Suite struct PasteboardSnapshotTests {
    /// A private pasteboard per test, never the person's clipboard.
    private func pasteboard(_ test: String = #function) -> NSPasteboard {
        let board = NSPasteboard(name: .init("com.smarttype.tests.\(test)"))
        board.clearContents()
        return board
    }

    @Test func everyItemInEveryTypeComesBack() throws {
        let board = pasteboard()
        let rtf = Data(#"{\rtf1 Hello}"#.utf8)
        let custom = NSPasteboard.PasteboardType("com.smarttype.tests.custom")
        let text = NSPasteboardItem()
        text.setString("Hello", forType: .string)
        text.setData(rtf, forType: .rtf)
        let other = NSPasteboardItem()
        other.setData(Data([1, 2, 3]), forType: custom)
        board.writeObjects([text, other])
        let snapshot = try #require(PasteboardSnapshot(of: board))

        board.clearContents()
        board.setString("copied meanwhile", forType: .string)
        snapshot.restore(to: board)

        let items = try #require(board.pasteboardItems)
        #expect(items.count == 2)
        #expect(items.first?.string(forType: .string) == "Hello")
        #expect(items.first?.data(forType: .rtf) == rtf)
        #expect(items.last?.data(forType: custom) == Data([1, 2, 3]))
    }

    @Test func anEmptyPasteboardComesBackEmpty() throws {
        let board = pasteboard()
        let snapshot = try #require(PasteboardSnapshot(of: board))

        board.setString("copied meanwhile", forType: .string)
        snapshot.restore(to: board)

        #expect(board.pasteboardItems?.isEmpty ?? true)
    }

    /// Types listed with no data behind them: what a pasteboard looks like when macOS refuses
    /// SmartType its contents. Borrowing it then would lose the person's clipboard.
    @Test func contentsThatCannotBeReadAreNotSnapshotted() {
        let board = pasteboard()
        board.declareTypes([.string], owner: nil)

        #expect(PasteboardSnapshot(of: board) == nil)
    }
}
