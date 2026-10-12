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

    /// Buttons on the card: glass from macOS 26, bordered before it.
    @ViewBuilder func cardButtonStyle() -> some View {
        if #available(macOS 26, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }
}
