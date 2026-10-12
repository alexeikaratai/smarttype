/// A natural language, by its BCP 47 code.
package struct Language: Hashable, Sendable, CustomStringConvertible {
    package let code: String

    package init(code: String) {
        self.code = code
    }

    package var description: String { code }

    package static let english = Language(code: "en")
    package static let russian = Language(code: "ru")
}
