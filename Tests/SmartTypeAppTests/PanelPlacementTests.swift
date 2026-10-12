import CoreGraphics
import Testing

@testable import SmartTypeApp

@Suite struct PanelPlacementTests {
    private let size = CGSize(width: 300, height: 200)
    /// A 1440×900 screen with the Dock along the bottom and the menu bar on top.
    private let visible = CGRect(x: 0, y: 70, width: 1440, height: 805)

    @Test func thePanelOpensBelowAndRightOfThePointer() {
        let frame = PanelPlacement.frame(size: size, pointer: CGPoint(x: 500, y: 500), visibleFrame: visible)
        #expect(frame == CGRect(x: 512, y: 288, width: 300, height: 200))
    }

    @Test func nearTheRightEdgeItOpensToTheLeft() {
        let frame = PanelPlacement.frame(size: size, pointer: CGPoint(x: 1400, y: 500), visibleFrame: visible)
        #expect(frame.maxX == CGFloat(1400) - PanelPlacement.gap)
    }

    @Test func nearTheBottomItOpensAbove() {
        let frame = PanelPlacement.frame(size: size, pointer: CGPoint(x: 500, y: 120), visibleFrame: visible)
        #expect(frame.minY == CGFloat(120) + PanelPlacement.gap)
    }

    /// Wherever the pointer is, the panel stays on the screen: in the corners, and over the
    /// menu bar or the Dock, outside the visible area, where flipping alone is not enough.
    @Test(arguments: [
        CGPoint(x: 0, y: 70), CGPoint(x: 1440, y: 875), CGPoint(x: 1439, y: 71), CGPoint(x: 5, y: 870),
        CGPoint(x: 700, y: 890), CGPoint(x: 700, y: 30),
    ])
    func thePanelNeverLeavesTheVisibleArea(_ pointer: CGPoint) {
        let frame = PanelPlacement.frame(size: size, pointer: pointer, visibleFrame: visible)
        #expect(visible.contains(frame))
    }
}
