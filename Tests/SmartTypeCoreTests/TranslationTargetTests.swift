import Foundation
import Testing

@testable import SmartTypeCore

@Suite struct TranslationTargetTests {
    /// This Mac's languages, measured: English first, then Russian.
    private let preferred = [Locale.Language(identifier: "en-US"), Locale.Language(identifier: "ru-PL")]

    private func target(from source: String, picked: String? = nil, preferred: [Locale.Language]? = nil) -> String? {
        TranslationTarget.choose(
            for: Locale.Language(identifier: source), preferred: preferred ?? self.preferred,
            picked: picked.map { Locale.Language(identifier: $0) }
        ).languageCode?.identifier
    }

    /// The first of the person's languages the text is not already in.
    @Test(arguments: [("ru", "en"), ("en", "ru"), ("de", "en"), ("uk", "en")])
    func textGoesIntoThePersonsFirstOtherLanguage(_ source: String, _ expected: String) {
        #expect(target(from: source) == expected)
    }

    @Test func aPickedLanguageWins() {
        #expect(target(from: "ru", picked: "de") == "de")
    }

    /// A pick the text is already in would translate nothing, so the usual rule takes over.
    @Test func aPickTheTextIsAlreadyInIsPassedOver() {
        #expect(target(from: "en", picked: "en") == "ru")
    }

    @Test func textInThePersonsOnlyLanguageGoesIntoEnglish() {
        #expect(target(from: "ru", preferred: [Locale.Language(identifier: "ru")]) == "en")
        #expect(target(from: "en", preferred: [Locale.Language(identifier: "en")]) == "ru")
    }
}
