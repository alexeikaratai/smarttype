import SwiftUI

/// Settings ▸ General: whether SmartType may use Accessibility, and how to fix it when it may not
/// (`AccessSection`, which the welcome window shows too); and whether it opens at login.
struct GeneralView: View {
    let accessibility: AccessibilityViewModel
    let openAtLogin: OpenAtLoginViewModel

    var body: some View {
        Form {
            AccessSection(accessibility: accessibility)
            openAtLoginSection
        }
    }

    /// Named as macOS names it, "Open at Login" (measured in System Settings' strings).
    private var openAtLoginSection: some View {
        Section {
            Toggle(
                String(
                    localized: "Open at Login",
                    comment: "Settings ▸ General: the switch that starts SmartType at login, named as macOS names it"),
                isOn: Binding(get: { openAtLogin.isOn }, set: { openAtLogin.set($0) }))
            if openAtLogin.problem != nil {
                HStack {
                    Spacer()
                    Button(
                        String(
                            localized: "Open Login Items…",
                            comment: "Settings ▸ General: button that opens System Settings' Login Items")
                    ) {
                        openAtLogin.openLoginItems()
                    }
                }
            }
        } footer: {
            SettingsNote(openAtLoginNote)
        }
    }

    private var openAtLoginNote: String {
        switch openAtLogin.problem {
        case nil:
            String(
                localized: "Starts SmartType when you log in, so the shortcuts work from the start.",
                comment: "Settings ▸ General: what Open at Login does")
        case .needsApproval:
            String(
                localized: "SmartType is turned off in System Settings’ Login Items. Turn it on there.",
                comment: "Settings ▸ General: Open at Login was turned off in System Settings")
        case .refused:
            String(
                localized: "macOS did not change it. Try again, or set it in System Settings’ Login Items.",
                comment: "Settings ▸ General: macOS refused to change Open at Login")
        }
    }
}
