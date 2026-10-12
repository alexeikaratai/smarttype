import AppKit
import Testing

@testable import SmartTypeApp
@testable import SmartTypeEngines

@Suite struct PanelControllerTests {
    init() {
        _ = NSApplication.shared
    }

    private let visible = CGRect(x: 0, y: 70, width: 1440, height: 805)

    private func card(test: String = #function) -> TranslationViewModel {
        TranslationViewModel(
            original: "Привет", translator: FallbackTranslator(engines: [FakeTranslationEngine()]),
            choices: .forTest(test), preferred: [Locale.Language(identifier: "en")], copy: { _ in },
            openURL: { _ in })
    }

    /// Records the click watcher: whether it runs, and lets a test click elsewhere.
    private final class Clicks {
        var watching = 0
        var clickElsewhere: () -> Void = {}
    }

    /// Never brings anything forward: a test must not put a window on the screen.
    private func controller(_ clicks: Clicks = Clicks(), presented: @escaping (NSPanel) -> Void = { _ in })
        -> PanelController
    {
        PanelController(
            present: presented, pointer: { CGPoint(x: 500, y: 500) }, visibleFrame: { _ in self.visible },
            watchClicks: { handler in
                clicks.watching += 1
                clicks.clickElsewhere = handler
                return { clicks.watching -= 1 }
            })
    }

    @Test func theCardOpensAtThePointer() throws {
        var presented: [NSPanel] = []
        let panels = controller(presented: { presented.append($0) })

        panels.show(card())

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
            translator: FallbackTranslator(engines: [FakeTranslationEngine()]), choices: .forTest(#function),
            preferred: [Locale.Language(identifier: "en")], copy: { _ in }, openURL: { _ in })
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
    @Test func thePanelIsReused() {
        var presented: [NSPanel] = []
        let panels = controller(presented: { presented.append($0) })

        panels.show(card())
        panels.show(card())

        #expect(presented.count == 2)
        #expect(presented.first === presented.last)
    }

    /// Clicks elsewhere are watched only while the panel is up: nothing runs while it is closed.
    @Test func aClickElsewhereClosesThePanelAndStopsTheWatching() {
        let clicks = Clicks()
        let panels = controller(clicks)
        panels.show(card())
        #expect(clicks.watching == 1)

        clicks.clickElsewhere()

        #expect(!panels.isShown)
        #expect(clicks.watching == 0)
    }

    @Test func escapeClosesThePanel() throws {
        var presented: [NSPanel] = []
        let panels = controller(presented: { presented.append($0) })
        panels.show(card())

        try #require(presented.first).cancelOperation(nil)

        #expect(!panels.isShown)
        #expect(panels.card == nil)
    }

    /// The person clicked another window: the panel lost key status and goes away.
    @Test func losingKeyStatusClosesThePanel() throws {
        var presented: [NSPanel] = []
        let panels = controller(presented: { presented.append($0) })
        panels.show(card())

        try #require(presented.first).resignKey()

        #expect(!panels.isShown)
    }
}
