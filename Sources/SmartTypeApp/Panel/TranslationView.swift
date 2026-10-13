import AppKit
import SwiftUI

/// The translation card: which way it translates, the original small, the translation large
/// and selectable, and who translated it. It is as tall as its text, up to a limit past which
/// the translation scrolls, and the panel takes its size.
struct TranslationView: View {
    static let width: CGFloat = 380
    static let cornerRadius: CGFloat = 20
    private static let resultHeightLimit: CGFloat = 320

    let card: TranslationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            direction
            Text(card.original)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            result
            footer
        }
        .padding(18)
        .frame(width: Self.width, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .cardBackground(cornerRadius: Self.cornerRadius)
    }

    /// "RUSSIAN → ENGLISH": the picks themselves live in Settings ▸ Translation.
    private var direction: some View {
        HStack(spacing: 5) {
            Text(card.source.displayNameWithoutRegion)
            Image(systemName: "arrow.right")
                .imageScale(.small)
            Text(card.target.displayNameWithoutRegion)
        }
        .font(.caption.weight(.semibold))
        .textCase(.uppercase)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var result: some View {
        switch card.state {
        case .translating:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text(String(localized: "Translating…", comment: "Translation panel: while the engine works"))
                    .foregroundStyle(.secondary)
            }
        case .translated(let text, _):
            // Measured: under fixedSize a ScrollView is as tall as its text, and the frame caps it.
            ScrollView {
                Text(text)
                    .font(.title2)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: Self.resultHeightLimit)
            .fixedSize(horizontal: false, vertical: true)
        case .failed(let problem):
            ProblemView(problem: problem, openTranslationLanguages: card.openTranslationLanguages)
        }
    }

    private var footer: some View {
        HStack {
            if case .translated(_, let engine) = card.state {
                Text(
                    verbatim: "\(engine) · "
                        + String(localized: "on this Mac", comment: "Translation panel: after the engine's name")
                )
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            Spacer()
            // The icon alone, decided 2026-10-13: the word stays the label VoiceOver reads and the
            // tooltip, and ↩ still copies.
            Button(action: card.copyTranslation) {
                Label(copyTitle, systemImage: card.isCopied ? "checkmark" : "doc.on.doc")
                    .labelStyle(.iconOnly)
            }
            .help(copyTitle)
            .keyboardShortcut(.defaultAction)
            .cardButtonStyle()
            .disabled(!card.state.isTranslated)
        }
    }
}

extension TranslationView {
    private var copyTitle: String {
        card.isCopied
            ? String(localized: "Copied", comment: "Translation panel: after the translation was copied")
            : String(localized: "Copy", comment: "Translation panel: copies the translation")
    }
}

extension TranslationViewModel.State {
    var isTranslated: Bool {
        if case .translated = self { true } else { false }
    }
}
