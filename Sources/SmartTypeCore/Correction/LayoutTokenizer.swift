/// Splits a selection into words, runs of anything but whitespace with their punctuation
/// attached, and the whitespace between them, kept exactly as it was.
enum LayoutTokenizer {
    struct Token: Sendable {
        let text: String
        let isWord: Bool

        var word: String? { isWord ? text : nil }
    }

    static func tokens(of text: String) -> [Token] {
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
