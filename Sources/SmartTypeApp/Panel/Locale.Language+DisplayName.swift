import Foundation

extension Locale.Language {
    /// The name the person reads, in the app's language: "English (United Kingdom)", with the
    /// region only where it is not the language's usual one.
    var displayName: String {
        name(in: .current)
    }

    /// The language alone, for the panel's header. The macOS language list holds "ru-PL", which
    /// would read "Russian (Poland)". Traditional Chinese keeps "(Taiwan)": the script stays, and
    /// "zh-TW" is that script's shortest name (measured).
    var displayNameWithoutRegion: String {
        Locale.Language(languageCode: languageCode, script: script).displayName
    }

    /// Capitalized, as in a list: Russian names of languages begin with a small letter.
    func name(in locale: Locale) -> String {
        let name = locale.localizedString(forIdentifier: minimalIdentifier) ?? minimalIdentifier
        return name.prefix(1).uppercased(with: locale) + name.dropFirst()
    }
}
