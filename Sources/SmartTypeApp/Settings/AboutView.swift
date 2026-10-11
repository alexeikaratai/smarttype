import AppKit
import SwiftUI

/// Settings ▸ About, as in SmartDock: what SmartType is, who made it and where it lives.
struct AboutView: View {
    let info: AppInfo
    let openURL: (URL) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
            Text(verbatim: "SmartType")
                .font(.system(size: 18, weight: .semibold))
            Text(verbatim: info.versionLine)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(
                String(
                    localized: "Fixes text typed in the wrong keyboard layout and translates the selection.",
                    comment: "Settings ▸ About: what SmartType does")
            )
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 6)
            HStack {
                Button {
                    open(AppInfo.repository)
                } label: {
                    Text(verbatim: "GitHub")
                }
                Button(String(localized: "Changelog", comment: "Settings ▸ About: opens the release notes")) {
                    open(AppInfo.releases)
                }
            }
            Spacer()
            Text(verbatim: AppInfo.madeWithLove)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func open(_ address: String) {
        if let url = URL(string: address) {
            openURL(url)
        }
    }
}
