import Foundation
import Translation

/// Apple's on-device translation, from macOS 26: the text never leaves the Mac. It translates
/// only pairs already downloaded, which the person does in System Settings.
///
/// Translation.framework is linked weakly without any flag, since its API begins after
/// macOS 14 (measured with `otool -l`: LC_LOAD_WEAK_DYLIB), so the app still starts there.
package struct AppleTranslationEngine: TranslationEngine {
    package let name = "Apple"

    package init() {}

    package func translate(_ text: String, from source: Locale.Language, to target: Locale.Language) async throws
        -> String
    {
        guard #available(macOS 26, *) else { throw TranslationFailure.unavailable }
        switch await LanguageAvailability().status(from: source, to: target) {
        case .installed:
            break
        case .supported:
            throw TranslationFailure.languagesNotInstalled
        case .unsupported:
            throw TranslationFailure.unsupportedLanguages
        @unknown default:
            throw TranslationFailure.unsupportedLanguages
        }
        do {
            return try await TranslationSession(installedSource: source, target: target).translate(text).targetText
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw TranslationFailure.failed(error.localizedDescription)
        }
    }
}
