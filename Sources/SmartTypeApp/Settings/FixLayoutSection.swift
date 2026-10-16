import SwiftUI

/// Settings ▸ Languages, first: every layout enabled in macOS with a switch, the ones Fix Layout
/// works between, and Add Layout…, since layouts come from macOS. Two stay on at least; with
/// one layout in macOS, it says to add a second.
struct FixLayoutSection: View {
    let layouts: LayoutSettingsModel

    var body: some View {
        Section {
            ForEach(layouts.rows) { row in
                Toggle(row.name, isOn: Binding(get: { row.isOn }, set: { layouts.set(row.id, isOn: $0) }))
                    .disabled(!layouts.canSwitch(row))
            }
            Button(String(localized: "Add Layout…", comment: "Settings ▸ Languages: opens System Settings ▸ Keyboard"))
            {
                layouts.addLayout()
            }
            .help(
                String(
                    localized: "Opens System Settings ▸ Keyboard, where Edit… next to Input Sources adds one.",
                    comment: "Settings ▸ Languages: tooltip of Add Layout…, with the pane's own names"))
        } header: {
            Text(AppCommand.fixLayout.title)
        } footer: {
            SettingsNote(footnote)
        }
    }

    private var footnote: String {
        if layouts.needsASecondLayout {
            return String(
                localized:
                    "Add a second keyboard layout to fix text typed in the wrong one. Layouts come from System Settings ▸ Keyboard ▸ Input Sources.",
                comment: "Settings ▸ Languages: Fix Layout with one layout in macOS")
        }
        if layouts.needsASecondSwitchedOn {
            return String(
                localized: "Switch on a second layout to fix text typed in the wrong one.",
                comment: "Settings ▸ Languages: Fix Layout with one layout left on")
        }
        return String(
            localized:
                "Fix Layout retypes text between the layouts switched on here, two at least. Layouts come from System Settings ▸ Keyboard ▸ Input Sources, and one you add there joins them.",
            comment: "Settings ▸ Languages: how Fix Layout uses the layouts")
    }
}
