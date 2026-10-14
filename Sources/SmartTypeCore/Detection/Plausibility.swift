/// How believable a word is in a language, from "no word looks like this" to "a dictionary
/// knows it". Graded rather than yes or no, so a later judge can weigh in on ties.
package enum Plausibility: Int, Sendable {
    case impossible
    case unknown
    case likely
    case known
}

// MARK: - Comparable

extension Plausibility: Comparable {
    package static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
