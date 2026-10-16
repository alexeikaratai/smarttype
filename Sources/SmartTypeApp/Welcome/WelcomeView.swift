import AppKit
import SwiftUI

/// The welcome window's one page: what the shortcuts do, the permission they need, the layouts
/// Fix Layout works between and the languages translations go into. Everything here is in
/// Settings too, from the same sections.
struct WelcomeView: View {
    let accessibility: AccessibilityViewModel
    let layouts: LayoutSettingsModel
    let translation: TranslationSettingsModel
    let shortcuts: [AppCommand: KeyCombo]
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
                .padding(.horizontal, 24)
            Form {
                shortcutsSection
                AccessSection(accessibility: accessibility)
                FixLayoutSection(layouts: layouts)
                // Translation needs macOS 26: before it there is nothing to choose.
                if AppCommand.translate.isAvailable {
                    TranslationLanguagesSection(translation: translation)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            HStack {
                Spacer()
                Button(String(localized: "Done", comment: "Welcome window: closes it for good"), action: onDone)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 16)
        .frame(width: 460, height: 640)
        .task { await translation.loadLanguages() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(String(localized: "Welcome to SmartType", comment: "Welcome window: title"))
                    .font(.system(size: 18, weight: .semibold))
                Text(
                    String(
                        localized: "Fixes text typed in the wrong keyboard layout and translates the selection.",
                        comment: "Settings ▸ About: what SmartType does")
                )
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
        }
    }

    private var shortcutsSection: some View {
        Section {
            ForEach(AppCommand.allCases, id: \.self) { command in
                LabeledContent(command.title) {
                    Text(verbatim: shortcut(for: command))
                        .monospaced()
                        .foregroundStyle(.secondary)
                }
            }
        } footer: {
            SettingsNote(
                String(
                    localized: "Select text in any app and press a shortcut. Settings ▸ Shortcuts changes them.",
                    comment: "Welcome window: how the commands are used"))
        }
    }

    private func shortcut(for command: AppCommand) -> String {
        if let requirement = command.requirement, !command.isAvailable {
            return requirement
        }
        return shortcuts[command]?.displayString
            ?? String(localized: "None", comment: "Settings ▸ Shortcuts: a command without a shortcut")
    }
}
