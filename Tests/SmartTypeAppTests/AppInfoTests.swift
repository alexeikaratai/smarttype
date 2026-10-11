import Foundation
import Testing

@testable import SmartTypeApp

@Suite struct AppInfoTests {
    @Test func theVersionLineShowsTheVersionAndTheBuild() throws {
        let bundle = try temporaryBundle(info: ["CFBundleShortVersionString": "0.1.0", "CFBundleVersion": "1"])
        #expect(AppInfo(bundle: bundle).versionLine == "Version 0.1.0 (1)")
    }

    @Test func aBundleWithoutVersionsSaysSoInsteadOfFailing() throws {
        let bundle = try temporaryBundle(info: [:])
        #expect(AppInfo(bundle: bundle).versionLine == "Version ? (?)")
    }

    /// A real bundle on disk: `Bundle` reads `Contents/Info.plist` the way it does for the app.
    private func temporaryBundle(info: [String: String]) throws -> Bundle {
        let root = FileManager.default.temporaryDirectory.appending(path: "AppInfoTests-\(UUID().uuidString).bundle")
        let contents = root.appending(path: "Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let plist = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try plist.write(to: contents.appending(path: "Info.plist"))
        return try #require(Bundle(url: root))
    }
}
