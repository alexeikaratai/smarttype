/// Why an engine did not translate, kept so the panel can say it.
package enum TranslationFailure: Error, Equatable, Sendable {
    /// The engine cannot run on this Mac, like Apple's before macOS 26.
    case unavailable
    /// The engine runs, but this pair of languages has not been downloaded yet.
    case languagesNotInstalled
    /// The engine does not translate between these languages at all.
    case unsupportedLanguages
    /// The engine tried and failed.
    case failed(String)
}
