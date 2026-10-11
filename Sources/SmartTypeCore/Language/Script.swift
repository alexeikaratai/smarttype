/// A writing system, recognised by the Unicode block of a letter.
package enum Script: Hashable, Sendable {
    case latin
    case cyrillic

    /// The script of `character`, or `nil` for anything that is not a letter of a known script.
    package init?(of character: Character) {
        guard character.isLetter, let scalar = character.unicodeScalars.first else { return nil }
        switch scalar.value {
        case 0x41...0x5A, 0x61...0x7A, 0xC0...0x24F: self = .latin
        case 0x400...0x52F: self = .cyrillic
        default: return nil
        }
    }
}
