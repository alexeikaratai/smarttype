import AppKit
import Observation
import SmartTypeCore

/// Settings ▸ Languages, the Fix Layout part: every layout enabled in macOS, on unless the person
/// switched it off. Read when the window opens and comes forward, never polled.
@Observable final class LayoutSettingsModel {
    /// The Keyboard pane, which allows this link (its Info.plist); Input Sources there has Edit….
    private static let keyboardSettings = "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"

    struct Row: Identifiable, Equatable {
        let id: String
        let name: String
        let isOn: Bool
    }

    private(set) var rows: [Row] = []

    @ObservationIgnored private let choices: LayoutChoices
    @ObservationIgnored private let readEnabled: () -> [InputSourceLayout]
    @ObservationIgnored private let openURL: (URL) -> Void

    init(
        choices: LayoutChoices = LayoutChoices(),
        readEnabled: @escaping () -> [InputSourceLayout] = { InputSourceLayouts.read() },
        openURL: @escaping (URL) -> Void = { NSWorkspace.shared.open($0) }
    ) {
        self.choices = choices
        self.readEnabled = readEnabled
        self.openURL = openURL
        refresh()
    }

    /// One layout in macOS leaves nothing to fix between.
    var needsASecondLayout: Bool { rows.count < 2 }

    /// Two in macOS, but one left on: one was switched off, then another removed in macOS.
    var needsASecondSwitchedOn: Bool { !needsASecondLayout && rows.filter(\.isOn).count < 2 }

    /// Two stay on at least, or there is nothing to fix between.
    func canSwitch(_ row: Row) -> Bool {
        !row.isOn || rows.filter(\.isOn).count > 2
    }

    func set(_ id: String, isOn: Bool) {
        guard let row = rows.first(where: { $0.id == id }), canSwitch(row) else { return }
        if isOn {
            choices.switchedOff.remove(id)
        } else {
            choices.switchedOff.insert(id)
        }
        refresh()
    }

    /// Layouts come from macOS, so a new one is added there; the window reads them again when
    /// it comes back forward.
    func addLayout() {
        if let url = URL(string: Self.keyboardSettings) {
            openURL(url)
        }
    }

    /// Back from System Settings, where a layout may have been turned on or off.
    func refresh() {
        let switchedOff = choices.switchedOff
        rows = readEnabled().map {
            Row(id: $0.layout.id, name: $0.name, isOn: !switchedOff.contains($0.layout.id))
        }
    }
}
