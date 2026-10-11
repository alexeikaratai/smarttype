/// Retypes text as if the same keys had been pressed with another layout active:
/// "ghbdtn" typed with U.S. becomes "привет" in Russian – PC.
package struct LayoutConverter: Sendable {
    package let source: KeyboardLayout
    package let target: KeyboardLayout
    private let table: [String: String]
    /// Some keys type more than one character (Arabic lam-alef), so lookups try the
    /// longest text first.
    private let longestText: Int

    package init(from source: KeyboardLayout, to target: KeyboardLayout) {
        var table: [String: String] = [:]
        for (text, stroke) in source.keyStrokesByText {
            table[text] = target.output[stroke]
        }
        self.source = source
        self.target = target
        self.table = table
        longestText = table.keys.map(\.count).max() ?? 1
    }

    /// Text that no key of the source layout types passes through unchanged.
    package func convert(_ text: some StringProtocol) -> String {
        var result = ""
        var index = text.startIndex
        while index < text.endIndex {
            let (typed, next) = nextKey(in: text, at: index)
            result += typed
            index = next
        }
        return result
    }

    private func nextKey<Text: StringProtocol>(in text: Text, at start: Text.Index) -> (String, Text.Index) {
        for length in stride(from: longestText, through: 1, by: -1) {
            guard let end = text.index(start, offsetBy: length, limitedBy: text.endIndex) else { continue }
            if let typed = table[String(text[start..<end])] {
                return (typed, end)
            }
        }
        let next = text.index(after: start)
        return (String(text[start..<next]), next)
    }
}
