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
        withoutRegion.displayName
    }

    /// The language and its script: a translation needs no region, and macOS and Apple's engine
    /// list several of them for one language ("en-US", "en-GB").
    var withoutRegion: Locale.Language {
        Locale.Language(languageCode: languageCode, script: script)
    }

    /// `==` compares how a language was made: "ru" from an identifier is not "ru" from its parts,
    /// as "en-US" is not "en" (measured). The shortest identifier is what both mean.
    func isSameLanguage(as other: Locale.Language) -> Bool {
        minimalIdentifier == other.minimalIdentifier
    }

    /// Capitalized, as in a list: Russian names of languages begin with a small letter.
    func name(in locale: Locale) -> String {
        let name = locale.localizedString(forIdentifier: minimalIdentifier) ?? minimalIdentifier
        return name.prefix(1).uppercased(with: locale) + name.dropFirst()
    }
}
