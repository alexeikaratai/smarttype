import AppKit
import Testing

@testable import SmartTypeApp

/// Draws the README's screenshot of Settings, and asserts nothing.
///
/// It lives here because only the test bundle can build the real window. It is off unless
/// `SHOT_PATH` is set, so an ordinary `swift test` neither runs it nor writes a file: `make shot`
/// runs it, and `make bump` runs `make shot`, because the header shows the version (SmartDock's
/// picture, taken by hand, went stale for five releases). Off screen, the window's glass draws as
/// a plain light surface and the translation panel's not at all (measured), so the panel's picture
/// is taken by hand; it shows no version.
@Suite struct ShotTool {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SHOT_PATH"] != nil))
    func renderTheSettingsWindow() throws {
        _ = NSApplication.shared
        let environment = ProcessInfo.processInfo.environment
        let path = try #require(environment["SHOT_PATH"])
        // A test process has no icon of its own, and the header would show a folder.
        let processIcon = NSApp.applicationIconImage
        NSApp.applicationIconImage = NSImage(contentsOfFile: "Resources/AppIcon.icns")
        defer { NSApp.applicationIconImage = processIcon }

        let macOS = PermissionRecorder()
        macOS.isTrusted = true
        let controller = SettingsWindowController(
            hotKeys: HotKeyBindings(registrar: RecordingRegistrar(), store: .forTest(#function)),
            permission: macOS.permission(), info: AppInfo(version: environment["SHOT_VERSION"] ?? "?", build: ""),
            openURL: { _ in },
            present: { window in
                // Pinned, or the picture follows the appearance of the moment (SmartDock). A test
                // process cannot take the focus from the app in front, so the close button stays
                // in its inactive grey, as in SmartDock's picture (seen in both).
                window.appearance = NSAppearance(named: .aqua)
                window.orderFrontRegardless()
            })
        controller.show()
        let window = try #require(controller.window)
        window.displayIfNeeded()

        // The theme frame rather than the content, so the picture keeps the window's own chrome:
        // its rounded corners and its close button.
        let frame = try #require(window.contentView?.superview)
        let picture = try #require(frame.bitmapImageRepForCachingDisplay(in: frame.bounds))
        frame.cacheDisplay(in: frame.bounds, to: picture)
        try #require(picture.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: path))
        window.close()
    }
}
