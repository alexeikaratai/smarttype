import Foundation
import Translation

/// Apple's on-device translation, from macOS 26: the text never leaves the Mac. It translates
/// only pairs already downloaded, which the person does in System Settings.
///
/// Translation.framework is linked weakly without any flag, since its API begins after
/// macOS 14 (measured with `otool -l`: LC_LOAD_WEAK_DYLIB), so the app still starts there.
package struct AppleTranslationEngine: Translating {
    package let name = "Apple"

    package init() {}

    /// Every language Apple's engine supports, downloaded or not; empty before macOS 26.
    /// `@concurrent`, so the non-Sendable `LanguageAvailability` is made and asked in one
    /// isolation domain instead of crossing out of the caller's.
    @concurrent
    package static func supportedLanguages() async -> [Locale.Language] {
        guard #available(macOS 26, *) else { return [] }
        return await LanguageAvailability().supportedLanguages
    }

    /// Why a pair cannot be translated yet, from what `LanguageAvailability` says of it.
    @available(macOS 15, *)
    package static func failure(for status: LanguageAvailability.Status) -> TranslationFailure? {
        switch status {
        case .installed: nil
        case .supported: .languagesNotInstalled
        case .unsupported: .unsupportedLanguages
        @unknown default: .unsupportedLanguages
        }
    }

    /// What the session threw, as the chain needs it: a cancellation goes on as one, never as a
    /// failure, and a pair not downloaded keeps the panel's button to Translation Languages.
    /// Anything else, `alreadyCancelled` from a session nobody here cancelled included, is a
    /// failure the card shows: a cancellation the card would wait on forever.
    @available(macOS 26, *)
    package static func failure(for error: any Error) -> any Error {
        switch error {
        case is CancellationError:
            CancellationError()
        case TranslationError.notInstalled:
            TranslationFailure.languagesNotInstalled
        case TranslationError.unsupportedLanguagePairing, TranslationError.unsupportedSourceLanguage,
            TranslationError.unsupportedTargetLanguage:
            TranslationFailure.unsupportedLanguages
        default:
            Task.isCancelled ? CancellationError() : TranslationFailure.failed(error.localizedDescription)
        }
    }

    package func translate(_ text: String, from source: Locale.Language, to target: Locale.Language) async throws
        -> String
    {
        guard #available(macOS 26, *) else { throw TranslationFailure.unavailable }
        if let notReady = Self.failure(for: await LanguageAvailability().status(from: source, to: target)) {
            throw notReady
        }
        do {
            return try await TranslationSession(installedSource: source, target: target).translate(text).targetText
        } catch {
            throw Self.failure(for: error)
        }
    }
}
