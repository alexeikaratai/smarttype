import AppKit
import SwiftUI

/// Shows the translation card at the pointer, and closes it on Esc or a click anywhere else.
/// One panel serves the app's whole life; clicks are watched only while it is up.
final class PanelController {
    private(set) var card: TranslationViewModel?
    var isShown: Bool { card != nil }

    private let present: (NSPanel) -> Void
    private let pointer: () -> CGPoint
    private let visibleFrame: (CGPoint) -> CGRect
    private let watchClicks: (@escaping () -> Void) -> () -> Void
    private var stopWatchingClicks: (() -> Void)?
    /// Where the pointer was when the card opened; the card stays next to it as it grows.
    private var anchor = CGPoint.zero
    private lazy var panel: FloatingPanel = {
        let panel = FloatingPanel()
        panel.onClose = { [weak self] in self?.close() }
        return panel
    }()

    init(
        present: @escaping (NSPanel) -> Void = { $0.makeKeyAndOrderFront(nil) },
        pointer: @escaping () -> CGPoint = { NSEvent.mouseLocation },
        visibleFrame: @escaping (CGPoint) -> CGRect = { PanelController.visibleFrame(around: $0) },
        watchClicks: @escaping (@escaping () -> Void) -> () -> Void = { PanelController.watchClicksElsewhere($0) }
    ) {
        self.present = present
        self.pointer = pointer
        self.visibleFrame = visibleFrame
        self.watchClicks = watchClicks
    }

    func show(_ card: TranslationViewModel) {
        close()
        self.card = card
        panel.contentView = Self.clippedToTheCard(NSHostingView(rootView: TranslationView(card: card)))
        anchor = pointer()
        fitToCard()
        present(panel)
        stopWatchingClicks = watchClicks { [weak self] in self?.close() }
    }

    func close() {
        // Ordering the panel out takes its key status, which calls back here: once is enough.
        guard card != nil else { return }
        card = nil
        stopWatchingClicks?()
        stopWatchingClicks = nil
        panel.orderOut(nil)
    }

    /// Fits the panel to its card once the card has changed, in the same step as the change: a
    /// translation, or the reason there is none, has a height of its own. SwiftUI applies a
    /// change on its next pass, where AppKit grows the window from its bottom edge and the card
    /// jumps (measured). Laid out here, it is measured and placed before anything is drawn, from
    /// the pointer it opened at, so it grows away from it even if the mouse has moved since.
    func fitToCard() {
        guard let content = panel.contentView else { return }
        content.layoutSubtreeIfNeeded()
        let frame = PanelPlacement.frame(size: content.fittingSize, pointer: anchor, visibleFrame: visibleFrame(anchor))
        panel.setFrame(frame, display: true)
    }

    // MARK: - Private

    /// Nothing outside the card's rounded corners: in the panel, something under the glass filled
    /// the window's rectangle in light grey around them (seen live), where a bare glass card did
    /// not, so the clip covers whatever draws it.
    private static func clippedToTheCard(_ content: NSView) -> NSView {
        content.wantsLayer = true
        content.layer?.cornerRadius = TranslationView.cornerRadius
        content.layer?.cornerCurve = .continuous
        content.layer?.masksToBounds = true
        return content
    }

    /// The visible part of the screen under the point: no menu bar, no Dock.
    private static func visibleFrame(around point: CGPoint) -> CGRect {
        let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
        return screen?.visibleFrame ?? .zero
    }

    /// Clicks in other apps; a global monitor sees mouse clicks without any permission.
    private static func watchClicksElsewhere(_ handler: @escaping () -> Void) -> () -> Void {
        let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            MainActor.assumeIsolated { handler() }
        }
        return {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
}
