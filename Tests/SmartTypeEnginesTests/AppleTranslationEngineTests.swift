import Foundation
import Testing
import Translation

@testable import SmartTypeEngines

@Suite struct AppleTranslationEngineTests {
    private let ru = Locale.Language(identifier: "ru")
    private let en = Locale.Language(identifier: "en")

    /// The real engine, on-device. Runs only where Russian → English is downloaded; a CI runner
    /// usually has no packs, and the test is skipped there rather than failed.
    @Test(.enabled("Russian → English is downloaded") { await AppleTranslationEngineTests.isInstalled("ru", "en") })
    func russianBecomesEnglish() async throws {
        let text = try await AppleTranslationEngine().translate("Привет, как дела?", from: ru, to: en)
        #expect(text.localizedCaseInsensitiveContains("hello"))
    }

    @Test func aPairAppleDoesNotSupportIsSaidSo() async {
        await #expect(throws: Self.failureForAnUnsupportedPair) {
            try await AppleTranslationEngine().translate("Привет", from: ru, to: Locale.Language(identifier: "xx"))
        }
    }

    /// What `LanguageAvailability` says of a pair: a supported one not downloaded yet gets the
    /// panel's button to Translation Languages.
    @Test func whatAvailabilitySaysOfAPairIsTold() {
        guard #available(macOS 15, *) else { return }
        #expect(AppleTranslationEngine.failure(for: .installed) == nil)
        #expect(AppleTranslationEngine.failure(for: .supported) == .languagesNotInstalled)
        #expect(AppleTranslationEngine.failure(for: .unsupported) == .unsupportedLanguages)
    }

    /// What the session throws, read from the SDK: a pair not downloaded or not supported is said
    /// so, and its cancellation is never a failure.
    @Test func whatTheSessionThrowsIsTold() throws {
        guard #available(macOS 26, *) else { return }
        let told = { (error: any Error) in AppleTranslationEngine.failure(for: error) as? TranslationFailure }

        #expect(told(TranslationError.notInstalled) == .languagesNotInstalled)
        #expect(told(TranslationError.unsupportedLanguagePairing) == .unsupportedLanguages)
        #expect(told(TranslationError.internalError) == .failed(TranslationError.internalError.localizedDescription))
        #expect(AppleTranslationEngine.failure(for: CancellationError()) is CancellationError)
        // Nothing here cancelled it, so the card must not wait for a translation that never comes.
        #expect(
            told(TranslationError.alreadyCancelled) == .failed(TranslationError.alreadyCancelled.localizedDescription))
    }

    /// Below macOS 26 there is no engine to ask, so no pair gets as far as being unsupported.
    private static var failureForAnUnsupportedPair: TranslationFailure {
        guard #available(macOS 26, *) else { return .unavailable }
        return .unsupportedLanguages
    }

    static func isInstalled(_ source: String, _ target: String) async -> Bool {
        guard #available(macOS 26, *) else { return false }
        let status = await LanguageAvailability().status(
            from: Locale.Language(identifier: source), to: Locale.Language(identifier: target))
        return status == .installed
    }
}
