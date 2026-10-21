import Foundation
import Observation
import SmartTypeEngines

/// Settings ▸ Languages, the translation part: the person's languages, the primary first, and
/// "Read text as", which overrides recognition when it keeps getting a language wrong.
@Observable final class TranslationSettingsModel {
    private(set) var languages: [Locale.Language]
    private(set) var source: Locale.Language?
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
        languages = choices.languages
        source = choices.source
    }

    var primary: Locale.Language? { languages.first }

    func isPrimary(_ language: Locale.Language) -> Bool {
        primary?.isSameLanguage(as: language) == true
    }

    /// A translation always needs a language to go into.
    var canRemove: Bool { languages.count > 1 }

    /// What Apple's engine translates and the list does not hold yet, by name.
    var addable: [Locale.Language] {
        Self.byName(supported.filter { !holds($0, in: languages) })
    }

    /// The rows of "Read text as": the engine's languages and the person's. A pick always has a
    /// row, so the picker never shows a selection without one while the engine's list is on its way.
    var readableLanguages: [Locale.Language] {
        var rows = supported
        for language in languages + [source].compactMap(\.self) where !holds(language, in: rows) {
            rows.append(language)
        }
        return Self.byName(rows)
    }

    /// Moves the language to the top; the one it replaces becomes the next, where text in the
    /// new primary goes. Every edit starts from the stored list: the welcome window and
    /// Settings each keep a model, and the other may have changed it.
    func makePrimary(_ language: Locale.Language) {
        save([language] + choices.languages.filter { !$0.isSameLanguage(as: language) })
    }

    /// A language already in the list stays where it is: the list keeps one entry per language.
    func add(_ language: Locale.Language) {
        save(choices.languages + [language])
    }

    func remove(_ language: Locale.Language) {
        let stored = choices.languages
        guard stored.count > 1 else { return }
        save(stored.filter { !$0.isSameLanguage(as: language) })
    }

    func pick(source language: Locale.Language?) {
        choices.source = language
        source = language
    }

    /// Back to the window, after the other one may have changed the list or the pick.
    func refresh() {
        languages = choices.languages
        source = choices.source
    }

    /// Asks Apple's engine once per window. It lists a language once per region ("en-US",
    /// "en-GB": English nine times on macOS 27.0.1, measured) where the person's list says "en",
    /// and `Locale.Language` compares identifiers (measured), so both take one regionless form.
    func loadLanguages() async {
        guard !hasAskedForLanguages else { return }
        hasAskedForLanguages = true
        supported = TranslationChoices.oneEach(await supportedLanguages())
    }

    // MARK: - Private

    private static func byName(_ languages: [Locale.Language]) -> [Locale.Language] {
        languages.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }

    private func save(_ list: [Locale.Language]) {
        choices.languages = list
        languages = choices.languages
    }

    private func holds(_ language: Locale.Language, in list: [Locale.Language]) -> Bool {
        list.contains { $0.isSameLanguage(as: language) }
    }
}
