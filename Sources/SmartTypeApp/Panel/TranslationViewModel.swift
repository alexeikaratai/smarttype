import Foundation
import Observation
import SmartTypeCore
import SmartTypeEngines

/// The translation card's state: the text, the two languages, and how the translation went.
/// The languages come from the person's list in Settings ▸ Languages and from the text.
@Observable final class TranslationViewModel {
    enum State: Equatable {
        case translating
        case translated(String, engine: String)
        case failed(Problem)
    }

    /// What the card says instead of a translation.
    enum Problem: Equatable {
        case notDownloaded
        case unsupported
        case unavailable
        case tooLong
        case failed
    }

    /// Longer text would keep the engine busy for many seconds, and it cannot be interrupted
    /// (measured: about 1,800 characters took 13.8 s).
    static let maximumLength = 2_000
    static let translationLanguages =
        "x-apple.systempreferences:com.apple.Localization-Settings.extension?translationLanguages"

    let original: String
    let source: Locale.Language
    let target: Locale.Language
    private(set) var state = State.translating
    /// The Copy button says so until the panel closes.
    private(set) var isCopied = false

    private let translator: FallbackTranslator
    private let copy: (String) -> Void
    private let openURL: (URL) -> Void

    init(
        original: String, translator: FallbackTranslator, choices: TranslationChoices,
        copy: @escaping (String) -> Void, openURL: @escaping (URL) -> Void
    ) {
        self.original = original
        self.translator = translator
        self.copy = copy
        self.openURL = openURL
        let languages = choices.languages
        let source = choices.source ?? Self.detect(original, preferred: languages)
        self.source = source
        target = TranslationTarget.choose(for: source, preferred: languages)
    }

    func translate() async {
        guard original.count <= Self.maximumLength else {
            state = .failed(.tooLong)
            return
        }
        do {
            let outcome = try await translator.translate(original, from: source, to: target)
            state = .translated(outcome.text, engine: outcome.engine)
        } catch let noTranslation as FallbackTranslator.NoTranslation {
            state = .failed(Problem(noTranslation.skipped.last?.failure))
        } catch {
            // Cancelled: nobody is waiting for it any more.
        }
    }

    func copyTranslation() {
        guard case .translated(let text, _) = state else { return }
        copy(text)
        isCopied = true
    }

    /// System Settings ▸ General ▸ Language & Region ▸ Translation Languages, where pairs download.
    func openTranslationLanguages() {
        if let url = URL(string: Self.translationLanguages) {
            openURL(url)
        }
    }

    // MARK: - Private

    private static func detect(_ text: String, preferred: [Locale.Language]) -> Locale.Language {
        SourceLanguage.detect(text, preferred: preferred) ?? preferred.first ?? Locale.Language(identifier: "en")
    }
}

// MARK: - TranslationViewModel.Problem

extension TranslationViewModel.Problem {
    init(_ failure: TranslationFailure?) {
        switch failure {
        case .languagesNotInstalled: self = .notDownloaded
        case .unsupportedLanguages: self = .unsupported
        case .unavailable: self = .unavailable
        case .failed, nil: self = .failed
        }
    }
}
