import Foundation
import Testing

@testable import SmartTypeApp

@Suite struct AppInfoTests {
    @Test func theVersionLineShowsTheVersionAndTheBuild() throws {
        let line = try versionLine(info: ["CFBundleShortVersionString": "0.1.0", "CFBundleVersion": "1"])
        #expect(line == "Version 0.1.0 (1)")
    }

    @Test func aBundleWithoutVersionsSaysSoInsteadOfFailing() throws {
        #expect(try versionLine(info: [:]) == "Version ? (?)")
    }

    /// From a real bundle on disk, which `Bundle` reads as it does the app's `Contents/Info.plist`,
    /// and which is gone again afterwards.
    private func versionLine(info: [String: String]) throws -> String {
        let root = FileManager.default.temporaryDirectory.appending(path: "AppInfoTests-\(UUID().uuidString).bundle")
        defer { try? FileManager.default.removeItem(at: root) }
        let contents = root.appending(path: "Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let plist = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try plist.write(to: contents.appending(path: "Info.plist"))
        return AppInfo(bundle: try #require(Bundle(url: root))).versionLine
    }
}
