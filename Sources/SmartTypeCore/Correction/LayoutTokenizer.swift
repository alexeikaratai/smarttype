/// Splits a selection into words, runs of anything but whitespace with their punctuation
/// attached, and the whitespace between them, kept exactly as it was.
package enum LayoutTokenizer {
    package struct Token: Equatable, Sendable {
        package let text: String
        package let isWord: Bool

        package var word: String? { isWord ? text : nil }
    }

    package static func tokens(of text: String) -> [Token] {
        var tokens: [Token] = []
        var start = text.startIndex
        while start < text.endIndex {
            let isWord = !text[start].isWhitespace
            let end = text[start...].firstIndex { $0.isWhitespace == isWord } ?? text.endIndex
            tokens.append(Token(text: String(text[start..<end]), isWord: isWord))
            start = end
        }
        return tokens
    }
}
