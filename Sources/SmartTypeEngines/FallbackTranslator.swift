import Foundation

/// Asks engines in order until one translates, and keeps why the others did not. The MVP has
/// one engine; Phase 2 puts a local model in front of it.
package struct FallbackTranslator: Sendable {
    package struct Outcome: Equatable, Sendable {
        package let text: String
        package let engine: String
        package let skipped: [Skip]
    }

    package struct Skip: Equatable, Sendable {
        package let engine: String
        package let failure: TranslationFailure
    }

    /// No engine translated; every one's reason is here.
    package struct NoTranslation: Error, Equatable {
        package let skipped: [Skip]
    }

    private let engines: [any TranslationEngine]

    package init(engines: [any TranslationEngine]) {
        self.engines = engines
    }

    /// Cancellation stops the chain and reaches the caller as it is: it is not a failure.
    package func translate(_ text: String, from source: Locale.Language, to target: Locale.Language) async throws
        -> Outcome
    {
        var skipped: [Skip] = []
        for engine in engines {
            try Task.checkCancellation()
            do {
                let translation = try await engine.translate(text, from: source, to: target)
                return Outcome(text: translation, engine: engine.name, skipped: skipped)
            } catch let failure as TranslationFailure {
                skipped.append(Skip(engine: engine.name, failure: failure))
            }
        }
        throw NoTranslation(skipped: skipped)
    }
}
