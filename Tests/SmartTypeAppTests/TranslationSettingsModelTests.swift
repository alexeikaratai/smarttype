import Foundation
import Testing

@testable import SmartTypeApp

@Suite struct TranslationSettingsModelTests {
    private let german = Locale.Language(identifier: "de")
    private let russian = Locale.Language(identifier: "ru")

    @Test func itStartsFromWhatWasPickedBefore() {
        let choices = TranslationChoices.forTest(#function)
        choices.target = german

        let settings = TranslationSettingsModel(choices: choices, supportedLanguages: { [] })

        #expect(settings.source == nil)
        #expect(settings.target?.languageCode?.identifier == "de")
    }

    @Test func aPickIsRememberedForTheNextTranslation() {
        let choices = TranslationChoices.forTest(#function)
        let settings = TranslationSettingsModel(choices: choices, supportedLanguages: { [] })

        settings.pick(source: russian)
        settings.pick(target: german)

        #expect(choices.source?.languageCode?.identifier == "ru")
        #expect(choices.target?.languageCode?.identifier == "de")
    }

    /// "Detect automatically" and "My languages" are no pick at all.
    @Test func automaticIsNoPick() {
        let choices = TranslationChoices.forTest(#function)
        choices.source = russian
        choices.target = german
        let settings = TranslationSettingsModel(choices: choices, supportedLanguages: { [] })

        settings.pick(source: nil)
        settings.pick(target: nil)

        #expect(choices.source == nil)
        #expect(choices.target == nil)
    }

    /// The list comes from Apple's engine once, sorted by the names the person reads.
    @Test func theLanguagesAreAskedForOnceAndSortedByName() async {
        var asked = 0
        let settings = TranslationSettingsModel(
            choices: .forTest(#function),
            supportedLanguages: {
                asked += 1
                return [
                    Locale.Language(identifier: "ru"), Locale.Language(identifier: "de"),
                    Locale.Language(identifier: "en"),
                ]
            })

        await settings.loadLanguages()
        await settings.loadLanguages()

        let names = settings.languages.map(\.displayName)
        #expect(asked == 1)
        #expect(names.count == 3)
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }

    /// Apple's engine lists "en-US" and "de-DE"; a pick is stored as "en" and "de", and
    /// `Locale.Language` compares the identifiers (measured: "en-US" is not "en"). Both are put
    /// in one form, so the picker finds the row of what was picked.
    @Test func theEnginesLanguagesMatchTheStoredPicks() async {
        let choices = TranslationChoices.forTest(#function)
        choices.target = Locale.Language(identifier: "de-DE")
        let settings = TranslationSettingsModel(
            choices: choices, supportedLanguages: { [Locale.Language(identifier: "de-DE")] })

        await settings.loadLanguages()

        #expect(settings.languages.map(\.minimalIdentifier) == ["de"])
        #expect(settings.languages.first == settings.target)
    }

    /// A pick has a row before the engine's list arrives, so the picker never shows a
    /// selection without one.
    @Test func aPickIsListedBeforeTheLanguagesLoad() {
        let choices = TranslationChoices.forTest(#function)
        choices.source = german
        choices.target = german

        let settings = TranslationSettingsModel(choices: choices, supportedLanguages: { [] })

        #expect(settings.languages.map(\.minimalIdentifier) == ["de"])
    }
}
