import Foundation

/// The languages the person picked in Settings ▸ Translation. Nothing picked means: detect
/// the source, and translate into the person's own languages.
struct TranslationChoices {
    private static let sourceKey = "com.smarttype.translation.source"
    private static let targetKey = "com.smarttype.translation.target"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// `nil`: detect the language of each selection.
    var source: Locale.Language? {
        get { language(at: Self.sourceKey) }
        nonmutating set { store(newValue, at: Self.sourceKey) }
    }

    /// `nil`: the first of the person's languages the text is not in.
    var target: Locale.Language? {
        get { language(at: Self.targetKey) }
        nonmutating set { store(newValue, at: Self.targetKey) }
    }

    private func language(at key: String) -> Locale.Language? {
        defaults.string(forKey: key).map { Locale.Language(identifier: $0) }
    }

    private func store(_ language: Locale.Language?, at key: String) {
        if let language {
            defaults.set(language.minimalIdentifier, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
