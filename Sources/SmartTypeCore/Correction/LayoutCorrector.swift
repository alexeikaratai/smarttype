/// Fixes text typed with the wrong keyboard layout active: "ghbdtn" → "привет".
///
/// A selection one layout could have typed entirely is converted whole, punctuation included:
/// the person asked for exactly that. Mixed text is decided word by word, and a word is kept
/// unless its conversion reads better; a tie keeps it.
package struct LayoutCorrector {
    private typealias Token = LayoutTokenizer.Token
    private typealias Reading = (text: String, layoutID: String, plausibility: Plausibility)

    /// In the person's order, which settles a tie.
    private let layouts: [KeyboardLayout]
    /// From each layout, by its ID, into every other.
    private let convertersBySource: [String: [LayoutConverter]]
    /// For every character some layout types, the IDs of the layouts that type it.
    private let layoutIDsByCharacter: [Character: Set<String>]
    private let detector: LanguageDetector

    package init(layouts: [KeyboardLayout], detector: LanguageDetector) {
        self.layouts = layouts
        self.detector = detector
        var convertersBySource: [String: [LayoutConverter]] = [:]
        var layoutIDsByCharacter: [Character: Set<String>] = [:]
        for source in layouts {
            convertersBySource[source.id] = layouts.filter { $0.id != source.id }.flatMap {
                LayoutConverter.readings(from: source, to: $0)
            }
            for text in source.keyStrokesByText.keys where text.count == 1 {
                layoutIDsByCharacter[Character(text), default: []].insert(source.id)
            }
        }
        self.convertersBySource = convertersBySource
        self.layoutIDsByCharacter = layoutIDsByCharacter
    }

    /// Two layouts at least, or there is nothing to convert between.
    package var canConvert: Bool { layouts.count > 1 }

    /// For the log: which layouts it converts between, in the person's order.
    package var layoutIDs: [String] { layouts.map(\.id) }

    /// `nil` when nothing would change.
    package func correct(_ text: String) -> Correction? {
        let tokens = LayoutTokenizer.tokens(of: text)
        let sources = commonSourceIDs(of: tokens)
        let correction = sources.isEmpty ? wordByWord(tokens) : wholeSelection(tokens, typedIn: sources)
        guard let correction, correction.text != text else { return nil }
        return correction
    }

    // MARK: - Private

    /// The layouts that could have typed `word`. Characters no layout types don't count, and a
    /// word every layout could have typed, digits for one, says nothing: both give none. Two
    /// layouts that share letters, Russian and Ukrainian, can both be a word's source; two that
    /// type the same punctuation on different keys cannot (U.S. and Russian – PC "/", where
    /// Ukrainian – PC has none; measured), or a third layout would make it convert.
    private func sourceIDs(of word: String) -> Set<String> {
        let perCharacter = word.compactMap(layoutsTyping)
        guard let first = perCharacter.first else { return [] }
        let candidates = perCharacter.dropFirst().reduce(first) { $0.intersection($1) }
        guard candidates.count < layouts.count else { return [] }
        return candidates.count == 1 || word.contains(where: \.isLetter) ? candidates : []
    }

    /// A character no key types whole may be a letter and a combining mark typed on keys of
    /// their own (Thai's mai tho): then the layouts that type both.
    private func layoutsTyping(_ character: Character) -> Set<String>? {
        if let ids = layoutIDsByCharacter[character] {
            return ids
        }
        let perScalar = character.unicodeScalars.compactMap { layoutIDsByCharacter[Character($0)] }
        guard perScalar.count > 1, perScalar.count == character.unicodeScalars.count else { return nil }
        return perScalar.dropFirst().reduce(perScalar[0]) { $0.intersection($1) }
    }

    /// The layouts that could have typed every word that says something; none when two disagree.
    private func commonSourceIDs(of tokens: [Token]) -> Set<String> {
        let telling = tokens.compactMap(\.word).map(sourceIDs(of:)).filter { !$0.isEmpty }
        guard let first = telling.first else { return [] }
        return telling.dropFirst().reduce(first) { $0.intersection($1) }
    }

    /// Into the layout whose language reads best. A conversion that changes nothing, between two
    /// layouts that type the same letters, is not one.
    private func wholeSelection(_ tokens: [Token], typedIn sources: Set<String>) -> Correction? {
        let words = tokens.compactMap(\.word)
        let scored = converters(from: sources).filter { changesAnything($0, words) }.map {
            (converter: $0, plausibility: totalPlausibility(tokens, $0))
        }
        guard let converter = scored.max(by: { $0.plausibility < $1.plausibility })?.converter else { return nil }
        let text = tokens.map { token in token.word.map(converter.convert) ?? token.text }.joined()
        return Correction(text: text, targetLayoutID: converter.target.id)
    }

    private func wordByWord(_ tokens: [Token]) -> Correction? {
        var text = ""
        var targetLayoutID: String?
        for token in tokens {
            guard let better = token.word.flatMap(betterReading(of:)) else {
                text += token.text
                continue
            }
            text += better.text
            targetLayoutID = better.layoutID
        }
        return targetLayoutID.map { Correction(text: text, targetLayoutID: $0) }
    }

    /// The conversion of `word` that reads better than the word as typed, in whichever layout
    /// that could have typed it reads best.
    private func betterReading(of word: String) -> (text: String, layoutID: String)? {
        let sources = sourceIDs(of: word)
        let asTyped = layouts.filter { sources.contains($0.id) }
            .map { detector.plausibility(of: letters(word), as: $0.language) }.max()
        guard let asTyped else { return nil }
        // A conversion that changes nothing is no reading of its own, even into a layout that
        // could not have typed the word: one that lacks its keys lets them through as they are.
        let readings = converters(from: sources).compactMap { converter -> Reading? in
            let text = converter.convert(word)
            guard text != word else { return nil }
            return (text, converter.target.id, detector.plausibility(of: letters(text), as: converter.target.language))
        }
        guard let best = readings.max(by: { $0.plausibility < $1.plausibility }), best.plausibility > asTyped else {
            return nil
        }
        return (best.text, best.layoutID)
    }

    private func changesAnything(_ converter: LayoutConverter, _ words: [String]) -> Bool {
        words.contains { converter.convert($0) != $0 }
    }

    /// From each of `sources`, in the person's order, into every other layout.
    private func converters(from sources: Set<String>) -> [LayoutConverter] {
        layouts.filter { sources.contains($0.id) }.flatMap { convertersBySource[$0.id, default: []] }
    }

    private func totalPlausibility(_ tokens: [Token], _ converter: LayoutConverter) -> Int {
        tokens.compactMap(\.word).reduce(0) { total, word in
            total + detector.plausibility(of: letters(converter.convert(word)), as: converter.target.language).rawValue
        }
    }

    private func letters(_ text: String) -> String {
        String(text.filter(\.isLetter))
    }
}
