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
        await #expect(throws: TranslationFailure.unsupportedLanguages) {
            try await AppleTranslationEngine().translate("Привет", from: ru, to: Locale.Language(identifier: "xx"))
        }
    }

    static func isInstalled(_ source: String, _ target: String) async -> Bool {
        guard #available(macOS 26, *) else { return false }
        let status = await LanguageAvailability().status(
            from: Locale.Language(identifier: source), to: Locale.Language(identifier: target))
        return status == .installed
    }
}
