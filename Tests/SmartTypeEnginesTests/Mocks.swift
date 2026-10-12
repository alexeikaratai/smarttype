import Foundation
import os

@testable import SmartTypeEngines

/// An engine that answers what it is told and counts how often it was asked.
final class FakeEngine: TranslationEngine {
    let name: String
    private let answer: Result<String, TranslationFailure>
    private let calls = OSAllocatedUnfairLock(initialState: 0)

    init(name: String, answer: Result<String, TranslationFailure>) {
        self.name = name
        self.answer = answer
    }

    var callCount: Int { calls.withLock { $0 } }

    func translate(_ text: String, from source: Locale.Language, to target: Locale.Language) async throws -> String {
        calls.withLock { $0 += 1 }
        return try answer.get()
    }
}
