import AppKit

/// The right-click Services, "SmartType: Fix Layout" and "SmartType: Translate", answered by the
/// operations the hotkeys run. macOS hands the selected text over on a pasteboard of its own, so
/// the person's clipboard is never touched and no Accessibility permission is needed. Info.plist
/// names each method in `NSMessage`; a test keeps the two in step.
final class TextServiceProvider: NSObject {
    private let fixInPlace: (String) -> String?
    private let translateText: (String) -> Void

    /// `translateText` only starts the translation: Services answer at once.
    init(fixInPlace: @escaping (String) -> String?, translateText: @escaping (String) -> Void) {
        self.fixInPlace = fixInPlace
        self.translateText = translateText
        super.init()
    }

    /// The fixed text goes back on the service pasteboard, and macOS puts it in place of the
    /// selection, with undo. Nothing written back leaves the selection as it was.
    @objc func fixLayout(
        _ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        guard let text = pasteboard.string(forType: .string), let fixed = fixInPlace(text) else { return }
        pasteboard.clearContents()
        pasteboard.setString(fixed, forType: .string)
    }

    @objc func translate(
        _ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        guard let text = pasteboard.string(forType: .string) else { return }
        translateText(text)
    }
}
