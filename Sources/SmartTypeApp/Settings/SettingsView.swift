import AppKit
import SwiftUI

/// The Settings window's content, laid out as SmartDock's: the app on top, then the tabs.
struct SettingsView: View {
    let accessibility: AccessibilityViewModel
    let shortcuts: [Shortcut]
    let info: AppInfo
    let openURL: (URL) -> Void

    @State private var tab = SettingsTab.general

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            Picker(selection: $tab) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Text(tab.title).tag(tab)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            selectedTab
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .frame(width: 420, height: 400)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: "SmartType")
                    .font(.system(size: 18, weight: .semibold))
                Text(verbatim: "v\(info.version) · \(AppInfo.madeWithLove)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder private var selectedTab: some View {
        switch tab {
        case .general: GeneralView(accessibility: accessibility)
        case .shortcuts: ShortcutsView(shortcuts: shortcuts)
        case .about: AboutView(info: info, openURL: openURL)
        }
    }
}

/// The tabs, in the order the segmented control shows them.
enum SettingsTab: CaseIterable {
    case general
    case shortcuts
    case about

    var title: String {
        switch self {
        case .general: String(localized: "General", comment: "Settings tab")
        case .shortcuts: String(localized: "Shortcuts", comment: "Settings tab")
        case .about: String(localized: "About", comment: "Settings tab")
        }
    }
}
