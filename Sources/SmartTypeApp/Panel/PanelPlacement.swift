import CoreGraphics

/// Where the translation panel opens: just below and to the right of the pointer, flipped to
/// the left or above where that would leave the screen, and always inside its visible area.
enum PanelPlacement {
    /// Keeps the panel off the pointer, so it never covers what was just selected.
    static let gap: CGFloat = 12

    static func frame(size: CGSize, pointer: CGPoint, visibleFrame: CGRect) -> CGRect {
        // AppKit's y grows upwards, so below the pointer means a smaller y.
        var x = pointer.x + gap
        var y = pointer.y - gap - size.height
        if x + size.width > visibleFrame.maxX {
            x = pointer.x - gap - size.width
        }
        if y < visibleFrame.minY {
            y = pointer.y + gap
        }
        x = min(max(x, visibleFrame.minX), visibleFrame.maxX - size.width)
        y = min(max(y, visibleFrame.minY), visibleFrame.maxY - size.height)
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }
}
