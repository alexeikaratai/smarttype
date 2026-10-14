import Foundation
import Testing

@testable import SmartTypeCore

@Suite struct TranslationTargetTests {
    /// The person's list, the primary first: here English, then Russian.
    private let preferred = [Locale.Language(identifier: "en-US"), Locale.Language(identifier: "ru-PL")]

    private func target(from source: String, preferred: [Locale.Language]? = nil) -> String? {
        TranslationTarget.choose(
            for: Locale.Language(identifier: source), preferred: preferred ?? self.preferred
        ).languageCode?.identifier
    }

    /// The first of the person's languages the text is not already in.
    @Test(arguments: [("ru", "en"), ("en", "ru"), ("de", "en"), ("uk", "en")])
    func textGoesIntoThePersonsFirstOtherLanguage(_ source: String, _ expected: String) {
        #expect(target(from: source) == expected)
    }

    /// The primary wins for any other language, Polish included.
    @Test func thePrimaryWins() {
        let list = ["ru", "en"].map { Locale.Language(identifier: $0) }
        #expect(target(from: "pl", preferred: list) == "ru")
        #expect(target(from: "en", preferred: list) == "ru")
    }

    /// Text already in the primary goes into the next language of the list.
    @Test func textInThePrimaryGoesIntoTheNext() {
        let list = ["ru", "pl", "en"].map { Locale.Language(identifier: $0) }
        #expect(target(from: "ru", preferred: list) == "pl")
    }

    @Test func textInThePersonsOnlyLanguageGoesIntoEnglish() {
        #expect(target(from: "ru", preferred: [Locale.Language(identifier: "ru")]) == "en")
        #expect(target(from: "en", preferred: [Locale.Language(identifier: "en")]) == "ru")
    }
}
