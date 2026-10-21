import Foundation
import Testing

@testable import SmartTypeApp

@Suite struct TranslationChoicesTests {
    private let systemLanguages = ["en-US", "ru-PL", "en-GB"].map { Locale.Language(identifier: $0) }

    private func codes(_ languages: [Locale.Language]) -> [String] {
        languages.map(\.minimalIdentifier)
    }

    /// Until the person changes it, the list is their macOS languages, one entry per language:
    /// macOS lists regions ("ru-PL"), and a translation needs only the language.
    @Test func theListStartsAsTheMacOSLanguagesOneEntryEach() {
        let choices = TranslationChoices(
            defaults: .forTest(#function, part: "translation"), systemLanguages: systemLanguages)

        #expect(codes(choices.languages) == ["en", "ru"])
    }

    /// 0.2's "Translate into" pick was the language the person wanted; it becomes the primary.
    @Test func aTranslateIntoPickFromTheLastVersionComesFirst() {
        let defaults = UserDefaults.forTest(#function, part: "translation")
        defaults.set("de", forKey: "com.smarttype.translation.target")

        let choices = TranslationChoices(defaults: defaults, systemLanguages: systemLanguages)

        #expect(codes(choices.languages) == ["de", "en", "ru"])
    }

    /// A saved list wins over everything, and 0.2's pick is not read again.
    @Test func aSavedListWinsAndTheOldPickIsForgotten() {
        let defaults = UserDefaults.forTest(#function, part: "translation")
        defaults.set("de", forKey: "com.smarttype.translation.target")
        let choices = TranslationChoices(defaults: defaults, systemLanguages: systemLanguages)

        choices.languages = ["pl", "ru"].map { Locale.Language(identifier: $0) }

        #expect(codes(choices.languages) == ["pl", "ru"])
        #expect(defaults.string(forKey: "com.smarttype.translation.target") == nil)
    }

    /// The keys are frozen: renamed, an update would lose every person's list and pick.
    @Test func theListAndThePickAreReadFromTheirKeys() {
        let defaults = UserDefaults.forTest(#function, part: "translation")
        defaults.set(["pl", "ru"], forKey: "com.smarttype.translation.languages")
        defaults.set("de", forKey: "com.smarttype.translation.source")

        let choices = TranslationChoices(defaults: defaults, systemLanguages: systemLanguages)

        #expect(codes(choices.languages) == ["pl", "ru"])
        #expect(choices.source?.minimalIdentifier == "de")
    }

    /// An empty saved list would leave a translation nowhere to go, so it reads as none saved.
    @Test func anEmptySavedListReadsAsTheMacOSLanguages() {
        let defaults = UserDefaults.forTest(#function, part: "translation")
        defaults.set([String](), forKey: "com.smarttype.translation.languages")

        let choices = TranslationChoices(defaults: defaults, systemLanguages: systemLanguages)

        #expect(codes(choices.languages) == ["en", "ru"])
    }

    /// "Read text as" stays a pick of its own; nothing picked means recognize each selection.
    @Test func readTextAsIsRememberedAndAutomaticIsNoPick() {
        let choices = TranslationChoices.forTest(#function)
        #expect(choices.source == nil)

        choices.source = Locale.Language(identifier: "de")
        #expect(choices.source?.minimalIdentifier == "de")

        choices.source = nil
        #expect(choices.source == nil)
    }
}
