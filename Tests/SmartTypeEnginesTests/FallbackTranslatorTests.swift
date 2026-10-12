import Foundation
import Testing

@testable import SmartTypeEngines

@Suite struct FallbackTranslatorTests {
    private let ru = Locale.Language(identifier: "ru")
    private let en = Locale.Language(identifier: "en")

    @Test func theFirstEngineThatTranslatesAnswers() async throws {
        let chain = FallbackTranslator(engines: [FakeEngine(name: "Apple", answer: .success("Hello"))])

        let outcome = try await chain.translate("Привет", from: ru, to: en)

        #expect(outcome == .init(text: "Hello", engine: "Apple", skipped: []))
    }

    /// Phase 2 puts a local model first; when it cannot answer, the next one does, and the
    /// panel can say why the first was skipped.
    @Test func anEngineThatCannotAnswerIsSkippedWithItsReason() async throws {
        let chain = FallbackTranslator(engines: [
            FakeEngine(name: "Ollama", answer: .failure(.unavailable)),
            FakeEngine(name: "Apple", answer: .success("Hello")),
        ])

        let outcome = try await chain.translate("Привет", from: ru, to: en)

        #expect(outcome.engine == "Apple")
        #expect(outcome.skipped == [.init(engine: "Ollama", failure: .unavailable)])
    }

    @Test func whenNoEngineAnswersEveryReasonIsKept() async {
        let chain = FallbackTranslator(engines: [
            FakeEngine(name: "Ollama", answer: .failure(.unavailable)),
            FakeEngine(name: "Apple", answer: .failure(.languagesNotInstalled)),
        ])

        await #expect(
            throws: FallbackTranslator.NoTranslation(skipped: [
                .init(engine: "Ollama", failure: .unavailable), .init(engine: "Apple", failure: .languagesNotInstalled),
            ])
        ) {
            try await chain.translate("Привет", from: ru, to: en)
        }
    }

    /// Cancelling is not a failure to report: it stops the chain and reaches the caller as is.
    @Test func cancellingStopsTheChain() async {
        let apple = FakeEngine(name: "Apple", answer: .success("Hello"))
        let chain = FallbackTranslator(engines: [apple])

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await chain.translate("Привет", from: ru, to: en)
        }

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(apple.callCount == 0)
    }
}
