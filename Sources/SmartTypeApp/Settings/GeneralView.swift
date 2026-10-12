import SwiftUI

/// Settings ▸ General: whether SmartType may use Accessibility, and how to fix it when it may not.
struct GeneralView: View {
    @Bindable var accessibility: AccessibilityViewModel

    @State private var isConfirmingReset = false

    var body: some View {
        Form {
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
                            accessibility.requestAccess()
                        }
                        Button(
                            String(localized: "Reset Permission…", comment: "Button: clear a stale Accessibility grant")
                        ) {
                            isConfirmingReset = true
                        }
                    }
                    .disabled(accessibility.isResetting)
                }
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    note(
                        String(
                            localized: "Fix Layout needs it to copy the selected text and paste the fixed text back.",
                            comment: "Settings ▸ General: why Accessibility is needed"))
                    if !accessibility.isGranted {
                        note(
                            String(
                                localized:
                                    "If SmartType is switched on in System Settings but is still not allowed here, the permission went stale after an update: reset it.",
                                comment: "Settings ▸ General: when to reset"))
                    }
                }
            }
        }
        .confirmationDialog(
            String(localized: "Reset SmartType’s permission?", comment: "Reset confirmation: title"),
            isPresented: $isConfirmingReset
        ) {
            Button(
                String(
                    localized: "Reset and Restart", comment: "Reset confirmation: the button that resets and relaunches"
                ), role: .destructive
            ) {
                Task { await accessibility.reset() }
            }
        } message: {
            Text(
                String(
                    localized:
                        "SmartType leaves the list in System Settings and restarts, then asks again. Switch it on in the list that opens.",
                    comment: "Reset confirmation: what happens"))
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

    private func note(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
