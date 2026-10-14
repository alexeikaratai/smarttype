import Foundation

@testable import SmartTypeEngines

/// A translation engine that answers with the target's code in front of the text ("en: …"),
/// fails when told to, and can hold its first answer until the test lets it go.
actor FakeTranslationEngine: Translating {
    nonisolated let name = "Fake"
    private(set) var callCount = 0
    private let failure: TranslationFailure?
    private let holdsFirstAnswer: Bool
    private var held: CheckedContinuation<Void, Never>?
    private var waitingForTheFirstCall: [CheckedContinuation<Void, Never>] = []

    init(failure: TranslationFailure? = nil, holdsFirstAnswer: Bool = false) {
        self.failure = failure
        self.holdsFirstAnswer = holdsFirstAnswer
    }

    func translate(_ text: String, from source: Locale.Language, to target: Locale.Language) async throws -> String {
        callCount += 1
        if holdsFirstAnswer, callCount == 1 {
            await withCheckedContinuation { continuation in
                held = continuation
                for waiting in waitingForTheFirstCall {
                    waiting.resume()
                }
                waitingForTheFirstCall = []
            }
        }
        if let failure { throw failure }
        return "\(target.languageCode?.identifier ?? "?"): \(text)"
    }

    /// Returns once the first call is being held.
    func waitUntilAsked() async {
        guard held == nil else { return }
        await withCheckedContinuation { waitingForTheFirstCall.append($0) }
    }

    func releaseFirstAnswer() {
        held?.resume()
        held = nil
    }
}
