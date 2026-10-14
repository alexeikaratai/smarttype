/// Fixes text typed with the wrong keyboard layout active: "ghbdtn" → "привет".
///
/// A selection typed entirely in one layout is converted whole, punctuation included: the
/// person asked for exactly that. Mixed text is decided word by word, and a word is kept
/// unless its conversion reads better; a tie keeps it.
package struct LayoutCorrector {
    private typealias Token = LayoutTokenizer.Token

    private let layouts: [String: KeyboardLayout]
    private let converters: [String: [LayoutConverter]]
    /// For every character some layout types, the IDs of the layouts that type it.
    private let layoutIDsByCharacter: [Character: Set<String>]
    private let detector: LanguageDetector

    package init(layouts: [KeyboardLayout], detector: LanguageDetector) {
        self.layouts = Dictionary(uniqueKeysWithValues: layouts.map { ($0.id, $0) })
        self.detector = detector
        var converters: [String: [LayoutConverter]] = [:]
        var layoutIDsByCharacter: [Character: Set<String>] = [:]
        for source in layouts {
            converters[source.id] = layouts.filter { $0.id != source.id }.map { LayoutConverter(from: source, to: $0) }
            for text in source.keyStrokesByText.keys where text.count == 1 {
                layoutIDsByCharacter[Character(text), default: []].insert(source.id)
            }
        }
        self.converters = converters
        self.layoutIDsByCharacter = layoutIDsByCharacter
    }

    /// `nil` when nothing would change.
    package func correct(_ text: String) -> Correction? {
        let tokens = LayoutTokenizer.tokens(of: text)
        let sources = Set(tokens.compactMap { $0.word.flatMap(sourceLayout(of:)) })
        let correction =
            if sources.count == 1, let source = sources.first {
                wholeSelection(tokens, typedIn: source)
            } else {
                wordByWord(tokens)
            }
        guard let correction, correction.text != text else { return nil }
        return correction
    }

    // MARK: - Private

    /// The only layout that could have typed `word`; characters no layout types don't count.
    private func sourceLayout(of word: String) -> String? {
        let layoutIDsPerCharacter = word.compactMap { layoutIDsByCharacter[$0] }
        guard let first = layoutIDsPerCharacter.first else { return nil }
        let candidates = layoutIDsPerCharacter.reduce(first) { $0.intersection($1) }
        return candidates.count == 1 ? candidates.first : nil
    }

    private func wholeSelection(_ tokens: [Token], typedIn source: String) -> Correction? {
        // With two layouts there is one target; with more, the one whose language reads best.
        guard
            let converter = converters[source, default: []].max(by: {
                totalPlausibility(tokens, $0) < totalPlausibility(tokens, $1)
            })
        else { return nil }
        let text = tokens.map { token in token.word.map(converter.convert) ?? token.text }.joined()
        return Correction(text: text, targetLayoutID: converter.target.id)
    }

    private func wordByWord(_ tokens: [Token]) -> Correction? {
        var text = ""
        var targetLayoutID: String?
        for token in tokens {
            guard let word = token.word, let source = sourceLayout(of: word),
                let better = betterReading(of: word, typedIn: source)
            else {
                text += token.text
                continue
            }
            text += better.text
            targetLayoutID = better.layoutID
        }
        return targetLayoutID.map { Correction(text: text, targetLayoutID: $0) }
    }

    /// The conversion of `word` that reads better than the word as typed, if there is one.
    private func betterReading(of word: String, typedIn source: String) -> (text: String, layoutID: String)? {
        guard let language = layouts[source]?.language else { return nil }
        let asTyped = detector.plausibility(of: letters(word), as: language)
        let readings = converters[source, default: []].map { converter in
            let text = converter.convert(word)
            let plausibility = detector.plausibility(of: letters(text), as: converter.target.language)
            return (text: text, layoutID: converter.target.id, plausibility: plausibility)
        }
        guard let best = readings.max(by: { $0.plausibility < $1.plausibility }), best.plausibility > asTyped else {
            return nil
        }
        return (best.text, best.layoutID)
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
