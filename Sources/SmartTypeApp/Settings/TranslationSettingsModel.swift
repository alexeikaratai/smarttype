import Foundation
import Observation
import SmartTypeEngines

/// Settings ▸ Translation: the languages to translate from and into. `nil` is automatic: the
/// source is detected, and the target is the first of the person's languages the text is not in.
@Observable final class TranslationSettingsModel {
    private(set) var source: Locale.Language?
    private(set) var target: Locale.Language?
    private var supported: [Locale.Language] = []

    private let choices: TranslationChoices
    private let supportedLanguages: () async -> [Locale.Language]
    @ObservationIgnored private var hasAskedForLanguages = false

    init(
        choices: TranslationChoices = TranslationChoices(),
        supportedLanguages: @escaping () async -> [Locale.Language] = {
            await AppleTranslationEngine.supportedLanguages()
        }
    ) {
        self.choices = choices
        self.supportedLanguages = supportedLanguages
        source = choices.source
        target = choices.target
    }

    /// The pickers' rows, by name. The picks are always among them, so a picker never shows a
    /// selection it has no row for while the engine's list is on its way.
    var languages: [Locale.Language] {
        var rows = supported
        for pick in [source, target].compactMap(\.self) where !rows.contains(pick) {
            rows.append(pick)
        }
        return rows.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }

    func pick(source language: Locale.Language?) {
        choices.source = language
        source = language
    }

    func pick(target language: Locale.Language?) {
        choices.target = language
        target = language
    }

    /// Asks Apple's engine once per window. Its list says "en-US" where a stored pick says "en",
    /// and `Locale.Language` compares identifiers, so both take the shortest form.
    func loadLanguages() async {
        guard !hasAskedForLanguages else { return }
        hasAskedForLanguages = true
        supported = await supportedLanguages().map { Locale.Language(identifier: $0.minimalIdentifier) }
    }
}
