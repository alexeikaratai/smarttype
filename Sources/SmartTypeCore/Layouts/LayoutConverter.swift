/// Retypes text as if the same keys had been pressed with another layout active:
/// "ghbdtn" typed with U.S. becomes "привет" in Russian – PC.
struct LayoutConverter: Sendable {
    let target: KeyboardLayout
    private let table: [String: String]
    /// Some keys type more than one character (Arabic lam-alef), so lookups try the
    /// longest text first.
    private let longestText: Int

    /// `leavingOut`: texts read key by key instead of by the one key that types them whole.
    init(from source: KeyboardLayout, to target: KeyboardLayout, leavingOut: Set<String> = []) {
        var table: [String: String] = [:]
        for (text, stroke) in source.keyStrokesByText where !leavingOut.contains(text) {
            table[text] = target.output[stroke]
        }
        self.target = target
        self.table = table
        longestText = table.keys.map(\.count).max() ?? 1
    }

    /// Some keys type what other keys type one after another: Arabic – PC's B types «لا», which
    /// G and H type too (11 layouts on macOS 27 have such keys; measured). Such text is read
    /// both ways, the one key first, so the corrector keeps whichever reads better and the one
    /// key on a tie.
    static func readings(from source: KeyboardLayout, to target: KeyboardLayout) -> [LayoutConverter] {
        let texts = source.keyStrokesByText.keys
        let singles = Set(texts.filter { $0.count == 1 })
        let spelledOut = texts.filter { $0.count > 1 && $0.allSatisfy { singles.contains(String($0)) } }
        let byOneKey = LayoutConverter(from: source, to: target)
        guard !spelledOut.isEmpty else { return [byOneKey] }
        return [byOneKey, LayoutConverter(from: source, to: target, leavingOut: Set(spelledOut))]
    }

    /// Text that no key of the source layout types passes through unchanged.
    func convert(_ text: some StringProtocol) -> String {
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
        return (retypedScalarByScalar(String(text[start..<next])), next)
    }

    /// A character no key types whole can still be several keys' output: a combining mark typed
    /// on its own key joins the letter before it into one character (Thai's mai tho). Retyped
    /// scalar by scalar when a key types each of them, and passed through otherwise.
    private func retypedScalarByScalar(_ character: String) -> String {
        let typed = character.unicodeScalars.map { table[String($0)] }
        return typed.contains(nil) ? character : typed.compactMap(\.self).joined()
    }
}
