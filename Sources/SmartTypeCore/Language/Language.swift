/// A natural language, by its BCP 47 code.
package struct Language: Hashable, Sendable {
    package static let english = Language(code: "en")
    package static let russian = Language(code: "ru")

    package let code: String

    package init(code: String) {
        self.code = code
    }
}

// MARK: - CustomStringConvertible

extension Language: CustomStringConvertible {
    package var description: String { code }
}
