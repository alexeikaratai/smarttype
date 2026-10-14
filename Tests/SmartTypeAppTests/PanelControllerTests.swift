import AppKit
import Testing

@testable import SmartTypeApp
@testable import SmartTypeEngines

@Suite struct PanelControllerTests {
    init() {
        _ = NSApplication.shared
    }

    private let visible = CGRect(x: 0, y: 70, width: 1440, height: 805)

    private func makeCard(test: String = #function) -> TranslationViewModel {
        TranslationViewModel(
            original: "Привет", translator: FallbackTranslator(engines: [FakeTranslationEngine()]),
            choices: .forTest(test, systemLanguages: [Locale.Language(identifier: "en")]), copy: { _ in },
            openURL: { _ in })
    }

    /// Never brings anything forward: a test must not put a window on the screen.
    private func controller(
        _ clicks: ClickWatcherRecorder = ClickWatcherRecorder(), presented: @escaping (NSPanel) -> Void = { _ in }
    ) -> PanelController {
        PanelController(
            present: presented, pointer: { CGPoint(x: 500, y: 500) }, visibleFrame: { _ in self.visible },
            watchClicks: { clicks.watch($0) })
    }

    @Test func theCardOpensAtThePointer() throws {
        var presented: [NSPanel] = []
        let panels = controller(presented: { presented.append($0) })

        panels.show(makeCard())

        let panel = try #require(presented.first)
        let expected = PanelPlacement.frame(
            size: panel.frame.size, pointer: CGPoint(x: 500, y: 500), visibleFrame: visible)
        #expect(panel.frame == expected)
        #expect(panels.isShown)
    }

    /// The card fits its text: it grows when the translation arrives, from the pointer it
    /// opened at, so nothing jumps under the person's eyes, even if the mouse moved meanwhile.
    @Test func theCardGrowsWithItsTextAndKeepsItsPlace() async throws {
        var presented: [NSPanel] = []
        var mouse = CGPoint(x: 500, y: 500)
        let panels = PanelController(
            present: { presented.append($0) }, pointer: { mouse }, visibleFrame: { _ in self.visible },
            watchClicks: { _ in {} })
        let card = TranslationViewModel(
            original: String(repeating: "Привет, как дела? ", count: 12),
            translator: FallbackTranslator(engines: [FakeTranslationEngine()]),
            choices: .forTest(#function, systemLanguages: [Locale.Language(identifier: "en")]),
            copy: { _ in }, openURL: { _ in })
        panels.show(card)
        let panel = try #require(presented.first)
        let translating = panel.frame

        mouse = CGPoint(x: 900, y: 300)
        await card.translate()
        panels.fitToCard()

        #expect(panel.frame.height > translating.height)
        #expect(panel.frame.maxY == translating.maxY)
        #expect(panel.frame.minX == translating.minX)
    }

    /// One panel for the app's life, as the architecture's memory budget assumes.
    /// No window shadow: macOS outlined the clear window's rectangle in a thin dark line around
    /// the rounded glass card (seen live, 2026-10-13). Of three cards side by side, AppKit glass
    /// with the shadow, SwiftUI glass with it and without it, the person chose the last.
    @Test func thePanelDrawsNoWindowShadow() {
        #expect(!FloatingPanel().hasShadow)
    }

    /// Nothing outside the card's corners: in the real panel something under the glass filled the
    /// window's rectangle in light grey around the rounded card (seen live, 2026-10-13), where a
    /// bare glass card in a probe did not, so the clip covers whatever draws it.
    @Test func thePanelShowsNothingOutsideTheCardsCorners() throws {
        var presented: [NSPanel] = []
        let panels = controller(presented: { presented.append($0) })

        panels.show(makeCard())

        let layer = try #require(presented.first?.contentView?.layer)
        #expect(layer.masksToBounds)
        #expect(layer.cornerRadius == TranslationView.cornerRadius)
        #expect(layer.cornerCurve == .continuous)
    }

    @Test func thePanelIsReused() {
        var presented: [NSPanel] = []
        let panels = controller(presented: { presented.append($0) })

        panels.show(makeCard())
        panels.show(makeCard())

        #expect(presented.count == 2)
        #expect(presented.first === presented.last)
    }

    /// Clicks elsewhere are watched only while the panel is up: nothing runs while it is closed.
    @Test func aClickElsewhereClosesThePanelAndStopsTheWatching() {
        let clicks = ClickWatcherRecorder()
        let panels = controller(clicks)
        panels.show(makeCard())
        #expect(clicks.watching == 1)

        clicks.clickElsewhere()

        #expect(!panels.isShown)
        #expect(clicks.watching == 0)
    }

    @Test func escapeClosesThePanel() throws {
        var presented: [NSPanel] = []
        let panels = controller(presented: { presented.append($0) })
        panels.show(makeCard())

        try #require(presented.first).cancelOperation(nil)

        #expect(!panels.isShown)
        #expect(panels.card == nil)
    }

    /// The person clicked another window: the panel lost key status and goes away.
    @Test func losingKeyStatusClosesThePanel() throws {
        var presented: [NSPanel] = []
        let panels = controller(presented: { presented.append($0) })
        panels.show(makeCard())

        try #require(presented.first).resignKey()

        #expect(!panels.isShown)
    }
}
