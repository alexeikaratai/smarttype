import SwiftUI

extension View {
    /// The card's surface: Liquid Glass from macOS 26, the system material before it.
    @ViewBuilder func cardBackground(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(macOS 26, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.regularMaterial, in: shape)
        }
    }

    /// Buttons on the card, and the shortcut fields in Settings ▸ Shortcuts: glass from macOS 26,
    /// bordered before it. The shortcut fields show the bordered ones on macOS 14 and 15.
    @ViewBuilder func cardButtonStyle() -> some View {
        if #available(macOS 26, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }
}
