import Foundation
import Testing

@testable import SmartTypeApp

@Suite struct LanguageDisplayNameTests {
    /// Measured on macOS 27 with `localizedString(forIdentifier:)`.
    @Test(arguments: [
        ("en-GB", "en", "English (United Kingdom)"), ("en-GB", "ru", "Английский (Великобритания)"),
        ("de-DE", "ru", "Немецкий"), ("en-US", "en", "English"),
    ])
    func aLanguageIsNamedInTheAppsLanguage(_ identifier: String, _ locale: String, _ name: String) {
        #expect(Locale.Language(identifier: identifier).name(in: Locale(identifier: locale)) == name)
    }

    /// The person's macOS languages carry their region ("ru-PL"); the header leaves it out.
    @Test func theHeaderLeavesTheRegionOut() {
        let fromTheLanguageList = Locale.Language(identifier: "ru-PL")

        #expect(fromTheLanguageList.displayName != Locale.Language(identifier: "ru").displayName)
        #expect(fromTheLanguageList.displayNameWithoutRegion == Locale.Language(identifier: "ru").displayName)
    }

    @Test func traditionalChineseStaysApartFromSimplified() {
        let traditional = Locale.Language(identifier: "zh-TW").displayNameWithoutRegion
        #expect(traditional != Locale.Language(identifier: "zh-CN").displayNameWithoutRegion)
    }
}
