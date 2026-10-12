# SmartType — Business Plan

**Status:** draft for review, October 2026.
**Companion docs:** [Architecture](ARCHITECTURE.md) · [Delivery plan](DELIVERY.md)

## 1. Summary
SmartType is a lightweight macOS menu-bar assistant for people who type in more than one language:
- **One shortcut fixes text typed in the wrong layout** (`ghbdtn` → `привет`).
- **Another translates the selection** in a floating panel, without leaving the current app.

It runs locally, needs no account, and does no work while idle.

## 2. Problem
- **The wrong-layout loop.** Bilingual users regularly type a word or a whole sentence in the wrong layout, then have to delete it, switch and retype. macOS has no built-in fix.
- **Few Mac options.** Punto Switcher is the reference on Windows. On the Mac the choice is thin: niche, en/ru-only or subscription switchers (§5).
- **Translation breaks flow.** Translating a phrase means copying it into a browser or another app, and most popup translators send the text to cloud services.

## 3. Target users
| Segment | Job to be done | Why SmartType |
|---|---|---|
| Bilingual knowledge workers (RU/UA/BY/KZ ↔ EN; later HE, AR) | fix wrong-layout typing instantly | one shortcut, works in any app |
| Emigrants, people working in a second language | understand or phrase text in the other language | translation in place, next to the cursor |
| Privacy-sensitive teams (legal, finance, public sector) | text must not leave the machine | on-device engines only |
| Developers and writers who live in many apps | no friction, no resource hogs | native, 0% CPU while idle |

## 4. Value proposition
- **Fix in one keystroke.** Select the text, press ⌃⌥L, done. The keyboard also switches to the right layout.
- **Translate without switching apps.** ⌃⌥T shows the translation next to the cursor; Esc dismisses it.
- **Also in the right-click menu.** Both commands appear under Services («Службы») for selected text. From there, the layout fix replaces the text natively, without touching the clipboard.
- **Private by design.** Translation runs on-device now (Apple); a local LLM comes later. No servers, no accounts, no telemetry. Whenever SmartType borrows the clipboard, it puts the user's content back.
- **Feather-light and native.** Swift/AppKit, no Electron, nothing running while idle.
- **Built to grow.** A new keyboard layout is one data file; translation engines and AI "judges" plug in behind protocols.

## 5. Competitive landscape
| Product | Layout fix | Translation | Model | Notes |
|---|---|---|---|---|
| Punto Switcher (Yandex) | auto + hotkey | — | free | the reference on Windows; current Mac status unclear (verify) |
| Caramba Switcher | auto | — | limited free + subscription (~$1/mo or ~449 ₽/yr per third-party listings) | en/ru and standard layouts only |
| Lang Switcher / LangSwitcher | auto / hotkey | — | App Store / open source | single purpose |
| Easydict | — | popup, many engines incl. Apple | free, open source | cloud engines by default |
| Bob | — | popup + OCR | one-time purchase | translation only |
| DeepL app | — | app / popup | freemium, cloud | text goes to the cloud |
| Ditto | — | ⌘C twice → popup (Apple/DeepL) | — | clipboard-driven |
| **SmartType** | **hotkey + context menu now, auto later** | **popup, on-device** | open core (§7) | both jobs in one native, local-first tool |

**Gap:** we found no Mac tool that combines layout fixing with in-place translation, works local-first, and supports layouts beyond en/ru.

## 6. Product scope and roadmap
| Phase | Scope | Exit criteria |
|---|---|---|
| **MVP (v0.1)** | ⌃⌥L layout fix (en↔ru); ⌃⌥T translation panel on Apple's on-device engine (macOS 26+); both commands in the right-click Services menu; menu bar; permission onboarding | works in TextEdit, Notes, Mail, Safari, VS Code, Telegram; the clipboard is always restored; idle CPU 0% |
| **Phase 2 — AI** | local LLM engine (Ollama, `qwen2.5:3b`) in front of the Apple engine; LLM judge for ambiguous words | the panel shows which engine answered; instant fallback when Ollama is down |
| **Phase 3 — Auto mode** | Punto-style fixing while typing; the user's installed layouts (uk, he, ar…); hotkey settings | false-positive rate under target on a test corpus |
| **v1.0** | launch at login, updates, notarized builds, polished onboarding, website | public release |

## 7. Business model and distribution (to decide)
**Options:**
- **A.** Free and open source.
- **B.** Closed freemium.
- **C.** Open core.

**Working assumption: C, open core with a one-time Pro purchase.**
- The core (layout fix, on-device translation) is public. That builds trust and lets anyone verify the privacy claims.
- The Pro features (local AI, auto mode) are paid. A one-time price fits: with no servers to pay for, there is no reason for a subscription.

**Distribution:**
- Homebrew, through the author's tap, which SmartDock already uses: `brew install --cask alexeikaratai/tap/smarttype`.
- Direct download from GitHub Releases.
- Every tag publishes both automatically ([delivery plan](DELIVERY.md#release-and-distribution)).
- Release assets must be downloadable, so the repository goes public before the first release.
- Developer ID signing and notarization come once there is a certificate; until then builds are ad-hoc signed, as SmartDock's are.
- The Mac App Store is doubtful, because its sandbox restricts synthetic keystrokes into other apps. Verify this before planning around it.

**Costs:** the Apple Developer Program ($99/yr). There is no backend, and local AI has zero marginal cost.

## 8. Go-to-market
- **Communities** where the pain is acute: Habr, vc.ru, Russian- and Ukrainian-speaking Telegram tech channels, r/macapps, Product Hunt.
- **Search intent:** "Punto Switcher for Mac alternative", "fix wrong keyboard layout Mac".
- **Trust:** a public core repository plus Homebrew. The privacy claims can be checked in the code.

## 9. Success metrics
- **Activation:** share of installs that grant Accessibility in the first session.
- **Engagement:** fixes and translations per weekly active user; D7/D30 retention.
- **Quality:** crash-free sessions; fixes that are undone immediately.
- **Footprint:** 0.0% idle CPU and idle memory within the budget in [Architecture §1](ARCHITECTURE.md#1-goals-and-quality-attributes).

The MVP ships without telemetry. Until opt-in analytics exist, these metrics come from beta testers and proxies: downloads, issues, reviews.

## 10. Risks
| Risk | Impact | Mitigation |
|---|---|---|
| macOS privacy hardening. The macOS 27 SDK says the general pasteboard **asks** on programmatic reads; TCC rules also change. | prompts annoy users or features break | read the selection through Accessibility first; offer the context-menu path, which needs no clipboard; clear onboarding |
| Uneven Accessibility support (Electron, Java, terminals) | the selection can't be read | ⌘C fallback; an app compatibility test matrix |
| Synthetic ⌘C/⌘V while the hotkey's ⌃⌥ are still held | the copy or paste silently fails | wait until the modifiers are released (proven by Espanso and Sorla) |
| Editors that copy the whole line when nothing is selected (VS Code, JetBrains) | ⌃⌥L pastes a converted line | stop when Accessibility reports an empty selection; ⌘Z restores the text |
| Hotkey conflicts. Carbon lets several apps share a combo without reporting an error, so both react. | confusing double actions | sensible defaults; registration errors shown in the menu; configurable hotkeys in Phase 3 |
| Apple ships similar system features | weaker differentiation | focus on layout fixing, bilingual workflows and local AI |
| Niche market | limited revenue | more languages (uk, he, ar), auto mode, a Pro tier |

## 11. Open questions for review
1. **MVP translation.** Keep ⌃⌥T on Apple's on-device engine (macOS 26+ only), or move the whole translation feature to the AI phase?
   **Decided on 2026-10-12:** Apple's on-device engine. On macOS older than 26, Translate stays disabled until Phase 2's local LLM.
2. **Minimum macOS.** Keep 14 (as in the spec), or raise it to 26? Raising it simplifies the Translation API and Liquid Glass and removes `#available` branches.
   **Decided on 2026-10-12:** macOS 14 stays. The layout fix runs there; translation checks for macOS 26 at run time.
3. **Business model.** A, B or C?
4. **Next languages** after en/ru. What order for uk, he, ar?
5. **Name.** Check "SmartType" for trademark and App Store collisions before any branding work.
6. **Translation scope.** ru↔en only (the current plan), or any language → the user's language? The second needs on-device language detection with `NLLanguageRecognizer`; Apple's engine covers about two dozen languages.
   **Decided on 2026-10-12:** any language Apple's engine supports, into a language the person picks; the source is detected, or picked too. Measured on macOS 27.0.1: 21, that is 19 languages, with two variants each of English and Chinese. The defaults are settled in the Stage 3 plan.
7. **Text that can't be selected** (images, video, UI labels). Add on-screen OCR later? Vision supports Russian, but it needs the Screen Recording permission. Also: a dictionary card for single words (meanings, examples) in Phase 2?

## Sources
- [AlternativeTo: Punto Switcher alternatives](https://alternativeto.net/software/punto-switcher)
- [AlternativeTo: Caramba Switcher](https://alternativeto.net/software/caramba-switcher/about/)
- [iPhones.ru: ways to switch input languages on a Mac (2022)](https://www.iphones.ru/iNotes/4-sposoba-uluchshit-pereklyuchenie-yazykov-vvoda-na-mac-ot-prostogo-nazhatiya-knopki-do-avtomaticheskogo-09-04-2022)
- [Lang Switcher on the App Store](https://apps.apple.com/app/id1597566195)
- [Easydict on GitHub](https://github.com/tisfeng/Easydict)
- [Mac translation apps overview](https://as.nani.now/en/blog/mac-translation-apps)
- [Ditto](https://www.gingerbeardman.com/apps/ditto/)
- [Apple: Services properties (NSServices)](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/SysServices/Articles/properties.html)
