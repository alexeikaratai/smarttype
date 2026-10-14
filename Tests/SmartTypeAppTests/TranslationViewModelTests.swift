import Foundation
import Testing

@testable import SmartTypeApp
@testable import SmartTypeEngines

@Suite struct TranslationViewModelTests {
    private let english = Locale.Language(identifier: "en")
    private let russian = Locale.Language(identifier: "ru")
    private let german = Locale.Language(identifier: "de")

    private func model(
        _ original: String = "Привет, как дела?", engine: FakeTranslationEngine = FakeTranslationEngine(),
        choices: TranslationChoices? = nil, copied: @escaping (String) -> Void = { _ in },
        opened: @escaping (URL) -> Void = { _ in }, test: String = #function
    ) -> TranslationViewModel {
        TranslationViewModel(
            original: original, translator: FallbackTranslator(engines: [engine]),
            choices: choices ?? TranslationChoices.forTest(test), copy: copied, openURL: opened)
    }

    /// Russian text goes into the first of the person's languages it is not in: English.
    @Test func theSelectionIsTranslatedIntoThePersonsOtherLanguage() async {
        let engine = FakeTranslationEngine()
        let card = model(engine: engine)
        #expect(card.state == .translating)

        await card.translate()

        #expect(card.source.languageCode?.identifier == "ru")
        #expect(card.target.languageCode?.identifier == "en")
        #expect(card.state == .translated("en: Привет, как дела?", engine: "Fake"))
    }

    @Test(arguments: [
        (TranslationFailure.languagesNotInstalled, TranslationViewModel.Problem.notDownloaded),
        (.unsupportedLanguages, .unsupported), (.unavailable, .unavailable), (.failed("boom"), .failed),
    ])
    func whyItDidNotTranslateIsShown(_ failure: TranslationFailure, _ problem: TranslationViewModel.Problem) async {
        let card = model(engine: FakeTranslationEngine(failure: failure))

        await card.translate()

        #expect(card.state == .failed(problem))
    }

    /// Text in a language other than the primary goes into the primary: Polish into Russian.
    @Test func textInAnotherLanguageGoesIntoThePrimary() {
        let choices = TranslationChoices.forTest(#function)
        choices.languages = ["ru", "en", "pl"].map { Locale.Language(identifier: $0) }

        let card = model("Spotykamy się jutro o dziesiątej.", choices: choices)

        #expect(card.source.languageCode?.identifier == "pl")
        #expect(card.target.languageCode?.identifier == "ru")
    }

    /// Text in the primary goes into the next language of the list.
    @Test func textInThePrimaryGoesIntoTheNext() {
        let choices = TranslationChoices.forTest(#function)
        choices.languages = [russian, german]

        let card = model(choices: choices)

        #expect(card.target.languageCode?.identifier == "de")
    }

    /// Alone, "привет" reads as Bulgarian (0.53, measured); the person's list settles it.
    @Test func aShortWordIsReadAsOneOfThePersonsLanguages() {
        let choices = TranslationChoices.forTest(#function)
        choices.languages = [english, russian]

        let card = model("привет", choices: choices)

        #expect(card.source.languageCode?.identifier == "ru")
        #expect(card.target.languageCode?.identifier == "en")
    }

    /// "Read text as" overrides recognition, for text it keeps getting wrong.
    @Test func readTextAsOverridesRecognition() {
        let choices = TranslationChoices.forTest(#function)
        choices.languages = [russian, english]
        choices.source = german

        let card = model(choices: choices)

        #expect(card.source.languageCode?.identifier == "de")
        #expect(card.target.languageCode?.identifier == "ru")
    }

    /// Long selections would keep the engine busy for many seconds (measured: 1,800
    /// characters took 13.8 s), so they are refused before it is asked.
    @Test func textOverTheLimitIsNotSentToTheEngine() async {
        let engine = FakeTranslationEngine()
        let card = model(String(repeating: "а", count: TranslationViewModel.maximumLength + 1), engine: engine)

        await card.translate()

        #expect(card.state == .failed(.tooLong))
        #expect(await engine.callCount == 0)
    }

    /// The button then reads "Copied" until the panel closes, so the person sees it worked.
    @Test func copyPutsTheTranslationOnTheClipboard() async {
        var copied: [String] = []
        let card = model(copied: { copied.append($0) })
        await card.translate()
        #expect(!card.isCopied)

        card.copyTranslation()

        #expect(copied == ["en: Привет, как дела?"])
        #expect(card.isCopied)
    }

    @Test func thereIsNothingToCopyBeforeTheTranslation() {
        var copied: [String] = []
        let card = model(copied: { copied.append($0) })

        card.copyTranslation()

        #expect(copied.isEmpty)
        #expect(!card.isCopied)
    }

    /// A pair not downloaded yet: the panel offers System Settings' Translation Languages.
    @Test func aMissingPairOpensTranslationLanguages() async throws {
        var opened: [URL] = []
        let card = model(engine: FakeTranslationEngine(failure: .languagesNotInstalled), opened: { opened.append($0) })
        await card.translate()

        card.openTranslationLanguages()

        let url = try #require(opened.first)
        #expect(url.absoluteString.hasPrefix("x-apple.systempreferences:com.apple.Localization-Settings.extension"))
    }
}
