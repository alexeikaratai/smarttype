/// One opinion on how plausible a word is in a language.
///
/// Not `Sendable`: a scorer may wrap a main-thread service such as `NSSpellChecker`, so a
/// scorer, and whatever holds it, runs where it was made.
package protocol WordScorer {
    func score(_ word: String, as language: Language) -> Plausibility
}
