/// A natural language: its BCP 47 code and the script it is written in.
package struct Language: Hashable, Sendable, CustomStringConvertible {
    package let code: String
    package let script: Script

    package init(code: String, script: Script) {
        self.code = code
        self.script = script
    }

    package var description: String { code }

    package static let english = Language(code: "en", script: .latin)
    package static let russian = Language(code: "ru", script: .cyrillic)
}
