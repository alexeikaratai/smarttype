import AppKit
import SwiftUI

/// The Settings window's content, laid out as SmartDock's: the app on top, then the tabs.
struct SettingsView: View {
    let accessibility: AccessibilityViewModel
    let openAtLogin: OpenAtLoginViewModel
    let translation: TranslationSettingsModel
    let layouts: LayoutSettingsModel
    let shortcuts: ShortcutsViewModel
    let info: AppInfo
    let openURL: (URL) -> Void

    @State private var tab = SettingsTab.general

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
                .padding(.horizontal, 24)
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
            .padding(.horizontal, 24)
            // Grouped forms, as in System Settings, on the window's own background.
            selectedTab
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.bottom, 8)
        .frame(width: 460, height: 420)
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
        case .general: GeneralView(accessibility: accessibility, openAtLogin: openAtLogin)
        case .languages: LanguagesView(translation: translation, layouts: layouts)
        case .shortcuts: ShortcutsView(model: shortcuts)
        case .about: AboutView(info: info, openURL: openURL).padding([.horizontal, .bottom], 24)
        }
    }
}

// MARK: - SettingsTab

/// The tabs, in the order the segmented control shows them.
enum SettingsTab: CaseIterable {
    case general
    case languages
    case shortcuts
    case about

    var title: String {
        switch self {
        case .general: String(localized: "General", comment: "Settings tab")
        case .languages: String(localized: "Languages", comment: "Settings tab")
        case .shortcuts: String(localized: "Shortcuts", comment: "Settings tab")
        case .about: String(localized: "About", comment: "Settings tab")
        }
    }
}
