import SwiftUI

/// Settings ▸ General: whether SmartType may use Accessibility, and how to fix it when it may not.
struct GeneralView: View {
    @Bindable var accessibility: AccessibilityViewModel

    var body: some View {
        Form {
            Section {
                LabeledContent(AccessibilityPermission.settingName) {
                    status
                }
                if !accessibility.isGranted {
                    accessButtons
                }
            } footer: {
                notes
            }
        }
        .alert(
            String(localized: "Couldn’t reset the permission", comment: "Alert after tccutil failed: title"),
            isPresented: $accessibility.isShowingResetFailure
        ) {
        } message: {
            Text(
                verbatim: String(
                    localized: "Run this command in Terminal:",
                    comment: "Alert after tccutil failed: before the command") + "\n" + accessibility.manualResetCommand
            )
        }
    }

    /// One button, from Settings as from the menu and the alerts: see `grantAccess()`.
    private var accessButtons: some View {
        HStack {
            Spacer()
            Button(
                String(
                    localized: "Grant Access…",
                    comment: "Button and menu item: add SmartType to the Accessibility list and open it")
            ) {
                Task { await accessibility.grantAccess() }
            }
            .disabled(accessibility.isGranting)
        }
    }

    private var notes: some View {
        VStack(alignment: .leading, spacing: 6) {
            note(
                String(
                    localized:
                        "Fix Layout and Translate need it to copy the selected text, and Fix Layout to paste the fixed text back.",
                    comment: "Settings ▸ General: why Accessibility is needed"))
            if !accessibility.isGranted {
                note(
                    String(
                        localized:
                            "Grant Access… restarts SmartType and opens the list in System Settings: switch SmartType on there. An entry an update left behind is cleared on the way.",
                        comment: "Settings ▸ General: what Grant Access does"))
            }
        }
    }

    private var status: some View {
        Label {
            Text(
                accessibility.isGranted
                    ? String(localized: "Allowed", comment: "Settings ▸ General: Accessibility status")
                    : String(localized: "Not allowed", comment: "Settings ▸ General: Accessibility status"))
        } icon: {
            Image(systemName: accessibility.isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(accessibility.isGranted ? Color.green : Color.yellow)
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
