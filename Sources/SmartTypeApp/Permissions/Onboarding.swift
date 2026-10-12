import AppKit

/// Says, in a modal alert, why a command could not run and what fixes it.
enum Onboarding {
    enum Problem {
        /// The Accessibility permission is off for SmartType.
        case accessibility
        /// Paste from Other Apps is set to Deny for SmartType, or macOS refused the read.
        case pasteboard
    }

    /// `true` when the person chose to fix it now.
    static func explain(_ problem: Problem) -> Bool {
        let alert = NSAlert()
        switch problem {
        case .accessibility:
            alert.messageText = String(
                localized: "SmartType needs a permission",
                comment: "Alert when a command runs without Accessibility: title")
            alert.informativeText =
                String(
                    localized:
                        "SmartType copies the selected text to fix or translate it, and pastes a fix back. macOS allows that only to apps switched on in System Settings ▸ Privacy & Security ▸",
                    comment: "Alert when a command runs without Accessibility: followed by the permission's name")
                + " " + AccessibilityPermission.settingName + ". "
                + String(
                    localized: "Grant Access… restarts SmartType and opens that list: switch it on there.",
                    comment: "Alert when a command runs without Accessibility: after the permission's name")
            alert.addButton(
                withTitle: String(
                    localized: "Grant Access…",
                    comment: "Button and menu item: add SmartType to the Accessibility list and open it"))
            alert.addButton(withTitle: String(localized: "Cancel", comment: "Button: close the alert"))
        case .pasteboard:
            alert.messageText = String(
                localized: "SmartType can’t read the clipboard", comment: "Alert when pasting is denied: title")
            alert.informativeText = String(
                localized:
                    "SmartType borrows the clipboard to fix or translate the selection and gives it back afterwards. Allow it in System Settings ▸ Privacy & Security ▸ Paste from Other Apps, then quit and reopen SmartType.",
                comment: "Alert when pasting is denied: how to allow it")
        }
        NSApp.activate()
        return alert.runModal() == .alertFirstButtonReturn
    }
}
