import Foundation
import Testing

@testable import SmartTypeApp

@Suite struct TranslationChoicesTests {
    private func choices(_ test: String = #function) -> TranslationChoices {
        let suite = "com.smarttype.tests.TranslationChoicesTests.\(test)"
        let defaults = UserDefaults(suiteName: suite) ?? UserDefaults()
        defaults.removePersistentDomain(forName: suite)
        return TranslationChoices(defaults: defaults)
    }

    /// Nothing picked: the source is detected and the target follows the person's languages.
    @Test func nothingIsPickedAtFirst() {
        let picks = choices()
        #expect(picks.source == nil)
        #expect(picks.target == nil)
    }

    @Test func picksAreRemembered() {
        let picks = choices()

        picks.source = Locale.Language(identifier: "de")
        picks.target = Locale.Language(identifier: "ru")

        #expect(picks.source?.languageCode?.identifier == "de")
        #expect(picks.target?.languageCode?.identifier == "ru")
    }

    @Test func detectingAgainForgetsThePickedSource() {
        let picks = choices()
        picks.source = Locale.Language(identifier: "de")

        picks.source = nil

        #expect(picks.source == nil)
    }
}
