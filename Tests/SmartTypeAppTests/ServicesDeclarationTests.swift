import AppKit
import Foundation
import Testing

@testable import SmartTypeApp

/// The Services declared in Info.plist, against the code that answers them. macOS calls
/// `<NSMessage>:userData:error:` on the provider, so a name that drifted would leave a menu item
/// that does nothing: the build breaks instead. Names and titles are frozen, since people bind
/// shortcuts to them in System Settings.
@Suite struct ServicesDeclarationTests {
    private static let resources = URL(filePath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "Resources")

    private static func infoPlist() throws -> [String: Any] {
        let data = try Data(contentsOf: resources.appending(path: "Info.plist"))
        return try #require(try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
    }

    private static func services() throws -> [String: [String: Any]] {
        let declared = try #require(try infoPlist()["NSServices"] as? [[String: Any]])
        return Dictionary(uniqueKeysWithValues: try declared.map { (try #require($0["NSMessage"] as? String), $0) })
    }

    @Test func everyCommandIsAServiceTheProviderAnswers() throws {
        let messages = try Self.services().keys

        #expect(Set(messages) == Set(AppCommand.allCases.map(\.storageName)))
        for message in messages {
            #expect(TextServiceProvider.instancesRespond(to: NSSelectorFromString("\(message):userData:error:")))
        }
    }

    @Test func theTitlesAreFrozen() throws {
        let titles = try Self.services().mapValues { ($0["NSMenuItem"] as? [String: String])?["default"] }

        #expect(titles == ["fixLayout": "SmartType: Fix Layout", "translate": "SmartType: Translate"])
    }

    /// For selected text in any app; without `NSRequiredContext`, macOS registers a service but
    /// does not show it. The port is the app's own name, which `servicesProvider` listens on.
    @Test(arguments: AppCommand.allCases)
    func aServiceTakesTheSelectedText(_ command: AppCommand) throws {
        let service = try #require(try Self.services()[command.storageName])

        #expect(service["NSSendTypes"] as? [String] == ["public.utf8-plain-text"])
        #expect(service["NSRequiredContext"] != nil)
        #expect(service["NSPortName"] as? String == (try Self.infoPlist()["CFBundleName"] as? String))
        #expect(service["NSKeyEquivalent"] == nil)
    }

    /// The fix gives its text back to replace the selection; Translate only reads.
    @Test func onlyTheFixReturnsText() throws {
        let declared = try Self.services()

        #expect(declared["fixLayout"]?["NSReturnTypes"] as? [String] == ["public.utf8-plain-text"])
        #expect(declared["translate"]?["NSReturnTypes"] == nil)
    }

    @Test func everyTitleHasARussianOne() throws {
        let data = try Data(contentsOf: Self.resources.appending(path: "ServicesMenu.xcstrings"))
        let catalog = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try #require(catalog["strings"] as? [String: [String: Any]])
        let titles = try Self.services().values.map {
            try #require(($0["NSMenuItem"] as? [String: String])?["default"])
        }

        #expect(titles.count == AppCommand.allCases.count)
        for title in titles {
            let russian = (strings[title]?["localizations"] as? [String: [String: [String: String]]])?["ru"]?[
                "stringUnit"]?["value"]
            #expect(russian?.isEmpty == false, "\(title) has no Russian title")
        }
    }
}
