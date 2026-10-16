import SwiftUI

/// Whether SmartType may use Accessibility, named as the running macOS names it, and while it may
/// not, its one fix: Grant Access…, as in the menu and the alerts (see `grantAccess()`). In
/// Settings ▸ General and in the welcome window.
struct AccessSection: View {
    @Bindable var accessibility: AccessibilityViewModel

    var body: some View {
        Section {
            LabeledContent(AccessibilityPermission.settingName) {
                status
            }
            if !accessibility.isGranted {
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
        } footer: {
            notes
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

    private var notes: some View {
        VStack(alignment: .leading, spacing: 6) {
            SettingsNote(
                String(
                    localized:
                        "Fix Layout and Translate need it to copy the selected text, and Fix Layout to paste the fixed text back.",
                    comment: "Settings ▸ General: why Accessibility is needed"))
            if !accessibility.isGranted {
                SettingsNote(
                    String(
                        localized:
                            "Grant Access… restarts SmartType and opens the list in System Settings: switch SmartType on there. An entry an update left behind is cleared on the way.",
                        comment: "Settings ▸ General: what Grant Access does"))
            }
        }
    }
}
