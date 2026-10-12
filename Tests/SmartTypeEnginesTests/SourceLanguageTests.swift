import Foundation
import Testing

@testable import SmartTypeEngines

@Suite struct SourceLanguageTests {
    private let preferred = [Locale.Language(identifier: "en-US"), Locale.Language(identifier: "ru-PL")]

    private func detect(_ text: String) -> String? {
        SourceLanguage.detect(text, preferred: preferred)?.languageCode?.identifier
    }

    /// Sentences: the recognizer is sure on its own (measured: 1.00).
    @Test(arguments: [("Привет, как дела?", "ru"), ("Wie geht es dir heute?", "de"), ("Bonjour tout le monde", "fr")])
    func aSentenceIsRecognizedOnItsOwn(_ text: String, _ expected: String) {
        #expect(detect(text) == expected)
    }

    /// Single words are not (measured: "hello" en 0.13, "привет" taken for Bulgarian at 0.53),
    /// so below 0.9 the person's own languages settle them.
    @Test(arguments: [("hello", "en"), ("привет", "ru"), ("мир", "ru")])
    func aShortWordIsReadAsOneOfThePersonsLanguages(_ text: String, _ expected: String) {
        #expect(detect(text) == expected)
    }

    @Test func textWithoutWordsHasNoLanguage() {
        #expect(detect("123 — 🙂") == nil)
    }
}
