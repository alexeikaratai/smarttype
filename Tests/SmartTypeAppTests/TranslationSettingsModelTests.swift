import Foundation
import Testing

@testable import SmartTypeApp

@Suite struct TranslationSettingsModelTests {
    private let german = Locale.Language(identifier: "de")
    private let polish = Locale.Language(identifier: "pl")

    private func settings(
        _ choices: TranslationChoices, supported: [Locale.Language] = []
    ) -> TranslationSettingsModel {
        TranslationSettingsModel(choices: choices, supportedLanguages: { supported })
    }

    private func codes(_ languages: [Locale.Language]) -> [String] {
        languages.map(\.minimalIdentifier)
    }

    @Test func itShowsThePersonsLanguagesPrimaryFirst() {
        let model = settings(.forTest(#function))

        #expect(codes(model.languages) == ["en", "ru"])
        #expect(model.primary?.minimalIdentifier == "en")
    }

    /// The primary moves to the top, and the one it replaces becomes the next: text in the new
    /// primary goes into the old one.
    @Test func makingALanguagePrimaryMovesItFirst() {
        let choices = TranslationChoices.forTest(#function)
        let model = settings(choices)

        model.makePrimary(Locale.Language(identifier: "ru"))

        #expect(codes(model.languages) == ["ru", "en"])
        #expect(codes(choices.languages) == ["ru", "en"])
    }

    @Test func anAddedLanguageGoesLastAndIsRemembered() {
        let choices = TranslationChoices.forTest(#function)
        let model = settings(choices)

        model.add(polish)

        #expect(codes(model.languages) == ["en", "ru", "pl"])
        #expect(codes(choices.languages) == ["en", "ru", "pl"])
    }

    /// The engine says "en-GB" where the list says "en": one English either way.
    @Test func aLanguageAlreadyInTheListIsNotAddedAgain() {
        let choices = TranslationChoices.forTest(#function)
        let model = settings(choices)

        model.add(Locale.Language(identifier: "en-GB"))

        #expect(codes(model.languages) == ["en", "ru"])
        #expect(codes(choices.languages) == ["en", "ru"])
    }

    @Test func aRemovedLanguageIsForgotten() {
        let choices = TranslationChoices.forTest(#function)
        let model = settings(choices)

        model.remove(Locale.Language(identifier: "ru"))

        #expect(codes(choices.languages) == ["en"])
    }

    /// A translation always needs somewhere to go. The saved list differs from the macOS
    /// languages, so an emptied list, which reads as those, cannot pass for a kept one.
    @Test func theLastLanguageIsKept() {
        let choices = TranslationChoices.forTest(#function)
        choices.languages = [german]
        let model = settings(choices)

        model.remove(german)

        #expect(codes(model.languages) == ["de"])
        #expect(codes(choices.languages) == ["de"])
        #expect(!model.canRemove)
    }

    /// Only what Apple's engine translates can be added, and not twice. The engine says
    /// "en-US" where the list says "en" (measured: `Locale.Language` compares identifiers).
    @Test func onlyLanguagesNotInTheListCanBeAdded() async {
        let model = settings(
            .forTest(#function),
            supported: ["en-US", "ru-RU", "de-DE", "pl-PL"].map { Locale.Language(identifier: $0) })

        await model.loadLanguages()

        #expect(codes(model.addable) == ["de", "pl"])
    }

    /// Asked once per window, and listed by the names the person reads.
    @Test func theEnginesLanguagesAreAskedForOnceAndSortedByName() async {
        var asked = 0
        let model = TranslationSettingsModel(
            choices: .forTest(#function),
            supportedLanguages: {
                asked += 1
                return ["pl", "de", "uk"].map { Locale.Language(identifier: $0) }
            })

        await model.loadLanguages()
        await model.loadLanguages()

        let names = model.addable.map(\.displayName)
        #expect(asked == 1)
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }

    /// The picker finds its selection by `==`, which tells "de" from an identifier and "de" from
    /// its parts apart (measured). Once the engine's "de-DE" is listed, the saved pick must still
    /// equal one of the rows, or the picker shows nothing selected.
    @Test func aSavedReadTextAsPickMatchesItsRowAfterTheLanguagesLoad() async throws {
        let choices = TranslationChoices.forTest(#function)
        choices.source = german
        let model = settings(choices, supported: [Locale.Language(identifier: "de-DE")])

        await model.loadLanguages()

        let pick = try #require(model.source)
        #expect(model.readableLanguages.filter { $0 == pick }.count == 1)
    }

    /// "Read text as": a pick holds for every translation, and has a row before the engine's
    /// list arrives, so the picker never shows a selection without one.
    @Test func readTextAsIsRememberedAndListedBeforeTheLanguagesLoad() throws {
        let choices = TranslationChoices.forTest(#function)
        let model = settings(choices)

        model.pick(source: german)

        let pick = try #require(model.source)
        #expect(choices.source?.minimalIdentifier == "de")
        #expect(model.readableLanguages.filter { $0 == pick }.count == 1)
        model.pick(source: nil)
        #expect(choices.source == nil)
    }
}
