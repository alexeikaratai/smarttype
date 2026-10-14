/// What one keyboard layout types: the text each physical key produces. Built-in layouts
/// come from two strings in ANSI key order; layouts read from macOS will fill `output`.
package struct KeyboardLayout: Hashable, Sendable, Identifiable {
    /// The macOS input source ID, e.g. "com.apple.keylayout.RussianWin".
    package let id: String
    package let language: Language
    /// What the writer means by each key.
    package let output: [KeyStroke: String]
    /// Text macOS really types for a key when it differs from `output`. Converting from
    /// this layout accepts both spellings.
    package let alternatives: [String: KeyStroke]

    package init(
        id: String, language: Language, output: [KeyStroke: String], alternatives: [String: KeyStroke] = [:]
    ) {
        self.id = id
        self.language = language
        self.output = output
        self.alternatives = alternatives
    }

    /// A layout from its unshifted and shifted characters, one per key of `KeyStroke.ansiKeyCodes`.
    package init(
        id: String, language: Language, unshifted: String, shifted: String, alternatives: [String: KeyStroke] = [:]
    ) {
        let codes = KeyStroke.ansiKeyCodes
        precondition(unshifted.count == codes.count && shifted.count == codes.count, "\(id): one character per key")
        var output: [KeyStroke: String] = [:]
        for (code, character) in zip(codes, unshifted) {
            output[KeyStroke(keyCode: code, isShifted: false)] = String(character)
        }
        for (code, character) in zip(codes, shifted) {
            output[KeyStroke(keyCode: code, isShifted: true)] = String(character)
        }
        self.init(id: id, language: language, output: output, alternatives: alternatives)
    }

    /// Every text this layout types, with the key that types it, alternatives included.
    var keyStrokesByText: [String: KeyStroke] {
        var result = alternatives
        for (stroke, text) in output {
            result[text] = stroke
        }
        return result
    }
}
