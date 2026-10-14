import Foundation

/// One way to translate text. `FallbackTranslator` asks engines in order.
package protocol Translating: Sendable {
    /// Shown under the translation, so the person knows who answered.
    var name: String { get }

    /// Throws `TranslationFailure` when this engine cannot answer, and lets cancellation
    /// through as it is.
    func translate(_ text: String, from source: Locale.Language, to target: Locale.Language) async throws -> String
}
