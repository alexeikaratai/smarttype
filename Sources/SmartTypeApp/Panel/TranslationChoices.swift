import Foundation

/// The languages the person set in Settings ▸ Languages, in UserDefaults under
/// `com.smarttype.translation.`: their list, the primary first, and "Read text as".
struct TranslationChoices {
    private static let sourceKey = "com.smarttype.translation.source"
    private static let languagesKey = "com.smarttype.translation.languages"
    /// 0.2's "Translate into" pick. Read only to put it first in a list nobody has saved yet.
    private static let earlierTargetKey = "com.smarttype.translation.target"

    private let defaults: UserDefaults
    private let systemLanguages: [Locale.Language]

    init(
        defaults: UserDefaults = .standard,
        systemLanguages: [Locale.Language] = Locale.preferredLanguages.map { Locale.Language(identifier: $0) }
    ) {
        self.defaults = defaults
        self.systemLanguages = systemLanguages
    }

    /// `nil`: recognize the language of each selection. Read in the form the lists use, so a
    /// picker matching by `==` finds its row ("de" from an identifier is not "de" from its parts).
    var source: Locale.Language? {
        get { defaults.string(forKey: Self.sourceKey).map { Locale.Language(identifier: $0).withoutRegion } }
        nonmutating set {
            if let newValue {
                defaults.set(newValue.minimalIdentifier, forKey: Self.sourceKey)
            } else {
                defaults.removeObject(forKey: Self.sourceKey)
            }
        }
    }

    /// The person's languages, the primary first: text in another language goes into the
    /// primary, and text in the primary into the next. Until the person changes it, the list is
    /// 0.2's "Translate into" pick followed by the macOS languages.
    var languages: [Locale.Language] {
        get {
            if let saved = defaults.stringArray(forKey: Self.languagesKey), !saved.isEmpty {
                return Self.oneEach(saved.map { Locale.Language(identifier: $0) })
            }
            let earlierTarget = defaults.string(forKey: Self.earlierTargetKey).map { Locale.Language(identifier: $0) }
            return Self.oneEach([earlierTarget].compactMap(\.self) + systemLanguages)
        }
        nonmutating set {
            defaults.set(Self.oneEach(newValue).map(\.minimalIdentifier), forKey: Self.languagesKey)
            defaults.removeObject(forKey: Self.earlierTargetKey)
        }
    }

    /// One entry per language, without its region: macOS lists "en-US" and "en-GB", and a
    /// translation needs only the language. The script stays, for Chinese.
    static func oneEach(_ languages: [Locale.Language]) -> [Locale.Language] {
        var seen: Set<String> = []
        return languages.map(\.withoutRegion).filter { seen.insert($0.minimalIdentifier).inserted }
    }
}
