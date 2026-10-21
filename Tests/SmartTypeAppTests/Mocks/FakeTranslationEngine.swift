import Foundation

@testable import SmartTypeEngines

/// A translation engine that answers with the target's code in front of the text ("en: …"),
/// or fails when told to.
actor FakeTranslationEngine: Translating {
    nonisolated let name = "Fake"
    private(set) var callCount = 0
    private let failure: TranslationFailure?

    init(failure: TranslationFailure? = nil) {
        self.failure = failure
    }

    func translate(_ text: String, from source: Locale.Language, to target: Locale.Language) async throws -> String {
        callCount += 1
        if let failure { throw failure }
        return "\(target.languageCode?.identifier ?? "?"): \(text)"
    }
}
