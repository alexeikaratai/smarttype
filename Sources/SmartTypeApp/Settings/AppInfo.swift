import Foundation

/// What Settings says about the app: the version from Info.plist, the author and the links.
struct AppInfo {
    static let repository = "https://github.com/alexeikaratai/smarttype"
    static let releases = "https://github.com/alexeikaratai/smarttype/releases"

    static var madeWithLove: String {
        String(localized: "Made with ❤ by Alex Karatai", comment: "Settings header and About: the author's signature")
    }

    let version: String
    let build: String

    init(bundle: Bundle = .main) {
        version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }

    /// "Version 0.1.0 (1)".
    var versionLine: String {
        String(localized: "Version", comment: "Settings ▸ About, before the version number") + " \(version) (\(build))"
    }
}
