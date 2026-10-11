# SmartType — Architecture

**Status:** the target design. Built so far: the menu-bar shell and global hotkeys (Stage 1), the correction core (2a), the Settings window (2b), and ⌃⌥L fixing the selection (2c–2d). What each later stage adds is tracked in [DELIVERY.md](DELIVERY.md) and `CHANGELOG.md`.
**Scope:** the architecture of the MVP. AI integrations (local LLM translation and an LLM "judge") come in Phase 2; the extension points for them are reserved here.
**Environment:** macOS 27, Xcode 27, Swift 6.4, Apple Silicon. Deployment target: macOS 14.
**Companion docs:** [Business plan](BUSINESS.md) · [Delivery plan](DELIVERY.md)

## 1. Goals and quality attributes
| Attribute | Target |
|---|---|
| Idle cost | 0.0% CPU; no timers, polling or event taps; zero idle wakeups |
| Memory | ≲ 40 MB idle footprint (17 MB until Settings is first opened, 34 MB with it open); the panel and engines are created lazily and the panel is reused |
| Latency | ⌃⌥L completes ≲ 150 ms after the keys are released, plus the paste settle time |
| Privacy | text never leaves the Mac and is never logged; the clipboard is restored; temporary pasteboard data is marked transient |
| Reliability | never paste stale clipboard content; never overwrite a clipboard the user changed in the meantime |
| Readability | one primary type per file (small companion types allowed); files ≲ 150 lines; names over comments |
| Extensibility | a new layout is one data file; a new engine, scorer or selection reader is one type behind a protocol |

## 2. System context
```
┌──────┐   select text + ⌃⌥L / ⌃⌥T     ┌──────────────────────────────┐
│ User │ ─────────────────────────────► │ SmartType · menu-bar agent   │
└──────┘ ◄────── panel / menu ───────── │ no Dock icon · idle 0% CPU   │
                                        └───────┬──────────────┬───────┘
          read selection (AX), synthetic ⌘C/⌘V, │              │ hot keys, input sources,
          Services: text in → fixed text out    ▼              ▼ permissions, translation
                               ┌──────────────────┐   ┌─────────────────────────────┐
                               │ Frontmost app    │   │ macOS services              │
                               │ any text field   │   │ Carbon · CGEvent · AX · TIS │
                               └──────────────────┘   │ NSPasteboard · Translation  │
                                                      └─────────────────────────────┘
                               ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
                                 Phase 2: local LLM (Ollama, 127.0.0.1)
                               └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

## 3. Modules
**Architectural style:** *functional core, imperative shell* with ports and adapters.
- `SmartTypeCore` is pure decision logic.
- The App target is the shell that touches the system.
- Protocols (ports) live where they are consumed; adapters over the C APIs live in `System/`.

```
SmartType.app
┌──────────────────────────────────────────────────────────────────────────┐
│ SmartType · executable (main.swift, ~6 lines)                            │
│      │                                                                   │
│      ▼                                                                   │
│ SmartTypeApp · @MainActor by default                                     │
│   App/          lifecycle, composition root, commands                    │
│   StatusBar/    NSStatusItem + NSMenu                                    │
│   ContextMenu/  macOS Services provider (right-click commands)           │
│   Actions/      LayoutFixAction, TranslateAction                         │
│   Panel/        FloatingPanel (AppKit) + TranslationView (SwiftUI)       │
│   Settings/     Settings window (AppKit) + its tabs (SwiftUI)            │
│   Permissions/  Accessibility, onboarding                                │
│   System/       adapters: hot keys, keystrokes, input sources,           │
│                 selection readers, clipboard, spelling                   │
│      │                                  │                                │
│      ▼                                  ▼                                │
│ SmartTypeEngines · nonisolated     SmartTypeCore · pure, nonisolated     │
│   TranslationEngine protocol ────►   layouts, converter, detection,      │
│   Apple on-device engine             correction (Foundation only)        │
│   Ollama, LLM judge (Phase 2)                                            │
└──────────────────────────────────────────────────────────────────────────┘
```
| Target | Owns | Depends on | Isolation |
|---|---|---|---|
| `SmartTypeCore` | languages, keyboard layouts, conversion, detection, correction | Foundation | nonisolated; data types `Sendable`; strict memory safety |
| `SmartTypeEngines` | translation engines, fallback chain; HTTP transport and LLM in Phase 2 | Core, Translation (weak-linked) | nonisolated async |
| `SmartTypeApp` | system adapters, actions, UI, composition root | Core, Engines, AppKit, SwiftUI, Carbon | MainActor by default |
| `SmartType` | process entry point | App | — |

**Why this split.** Targets are cut by isolation domain and dependencies:
- Pure logic is testable without UI.
- AppKit and Carbon code lives where the main actor is the default.
- The executable stays trivial, so everything else is testable.

Cross-target API uses `package` access, not `public`.

### 3.1 Runtime object graph (ownership)
```
AppDelegate
└─ AppComposition (composition root; lives as long as the app)
   ├─ HotKeyCenter ─────────┐
   ├─ StatusBarController ──┴─► perform(AppCommand) ─┬─► LayoutFixAction.fixSelection()
   │                                                  └─► TranslateAction.translateSelection()
   ├─ TextServiceProvider ─────► LayoutFixAction.fix(text) · TranslateAction.translate(text)
   ├─ SettingsWindowController (lazy; its window is freed on close)
   │   └─ SettingsView ── GeneralView ◄ AccessibilityViewModel ── AccessibilityPermission
   │
   ├─ LayoutFixAction
   │   ├─ ClipboardTransaction ── KeystrokeSender, PasteboardSnapshot
   │   ├─ LayoutCorrector (Core) ── LanguageDetector ── PhonotacticScorer, SpellCheckScorer
   │   └─ InputSourceSwitcher
   └─ TranslateAction
       ├─ selection readers: AXSelectionReader → ClipboardSelectionReader
       ├─ FallbackTranslator: [AppleTranslationEngine]      (lazy; Ollama joins in Phase 2)
       └─ PanelController (lazy) ── FloatingPanel ── TranslationView ◄ TranslationViewModel
```
- **Entry points.** Hotkeys and the menu go through `AppCommand`, a single routing point that the future settings UI will rebind. The context menu calls the actions' text-based API.
- **One core operation per action.** Each action has a single core operation: `fix(text)` or `translate(text)`. The selection-based entry points wrap it.

## 4. Concurrency and isolation
```
 Main actor                                     Off the main actor
 ─────────────────────────────────────────      ───────────────────────────────
 AppKit · SwiftUI · NSStatusItem · NSPanel       framework I/O awaited by Engines:
 Carbon hot keys · CGEvent · TIS · AX              TranslationSession.translate
 NSPasteboard · NSSpellChecker                     URLSession (Phase 2)
 Core: nonisolated, called synchronously here    results come back as Sendable values
 Actions ── await engine ──────────────────────►
```
**Language settings:**
- Swift 6 language mode with strict concurrency, in all targets.
- Upcoming features `ExistentialAny`, `MemberImportVisibility` and `NonisolatedNonsendingByDefault`.
- In App: `defaultIsolation(MainActor)` and `InferIsolatedConformances`.
- Warnings are errors, except deprecations.

**Runtime rules:**
- Each action runs as one task.
- Cancellation flows from the UI (Esc, closing the panel, pressing the hotkey again) down to the engines.
- No `Task.detached`.
- Carbon delivers its callbacks on the main thread; the code asserts this with `MainActor.assumeIsolated`.
- Engine code is nonisolated async and never blocks. The frameworks do their I/O off the main actor. Any future CPU-heavy work will be marked `@concurrent`.

## 5. Key flows

### 5.1 Fix layout (⌃⌥L)
```
User    Action        Clipboard         Front app     Core           TIS
 │ ⌃⌥L ─►│              │                 │             │              │
 │       │─ begin ─────►│ snapshot all    │             │              │
 │       │              │ wait ⌃⌥ release │             │              │
 │       │              │─ ⌘C ───────────►│             │              │
 │       │              │◄─ changeCount+1 │             │              │
 │       │◄─ "ghbdtn" ──│                 │             │              │
 │       │─ correct ─────────────────────────────────────►│              │
 │       │◄─ "привет" · RussianWin ───────────────────────│              │
 │       │─ paste ─────►│ write transient │             │              │
 │       │              │─ ⌘V ───────────►│ replaced    │              │
 │       │─ select RussianWin ──────────────────────────────────────────►│
 │       │              │ +250 ms: restore if changeCount still ours     │
```
**Guards and rules:**
- **Already running:** repeat presses are ignored, which also swallows hotkey auto-repeat.
- **No Accessibility permission:** show onboarding instead.
- **Nothing to act on:** if SmartType itself is frontmost, beep. Secure Input (a password field) joins this guard in Stage 4; until then its blocked ⌘C reads as nothing selected.
- **Nothing selected:** no `changeCount` bump means nothing was selected, so beep. Stale clipboard content is never used. The copied text is read only once the app's types have appeared, since an app clears the pasteboard before it writes.
- **Nothing to fix:** if the corrected text equals the input, nothing is pasted.
- **Restore:** 250 ms after ⌘V, so the app has read the paste; skipped if the user copied something in the meantime. The input source switches as the text lands, not after the restore.
- **Marking:** pasteboard writes carry `org.nspasteboard.TransientType` and `AutoGeneratedType`, so clipboard managers don't keep them.
- **Synthetic ⌘C/⌘V:** sent only after the physical ⌃⌥ are released (10 ms steps, ≤ 1 s), to `.cgSessionEventTap` with explicit flags.
- **Started from the menu:** the action starts after the menu closes, so the copy goes to the app the user was in.
- **Pasteboard access (macOS 15.4+):** reading the general pasteboard's contents asks the person; `changeCount`, `types` and the detection calls do not (SDK). This path reads twice, the snapshot and the copied text, so the person allows SmartType once in Privacy & Security ▸ Paste from Other Apps (the pane's name, measured). Set to Deny, or a pasteboard that lists types without data, means SmartType does not borrow it: ⌘C would overwrite a clipboard it could not put back. An alert says where to allow it. The context-menu path (§5.4) needs neither this nor Accessibility.

### 5.2 Translate (⌃⌥T)
```
User    Action         Selection          Panel        Translator    Engine
 │ ⌃⌥T ─►│               │                  │             │            │
 │       │─ close if open ─────────────────►│             │            │
 │       │─ read ───────►│ AX selected text │             │            │
 │       │               │ else ⌘C+restore  │             │            │
 │       │◄─ "Привет" ───│                  │             │            │
 │       │─ show "Translating…" ───────────►│ near cursor │            │
 │       │─ translate ru→en ──────────────────────────────►│─ request ─►│
 │       │◄─ outcome: text · engine · skipped ─────────────│◄───────────│
 │       │─ show result ───────────────────►│             │            │
 │ Esc / click outside ────────────────────►│ close ─► cancel task     │
```
- **Close the panel first.** While the panel is the key window, a synthetic ⌘C would go to the panel itself.
- **Selection readers.** A chain of `SelectionReader`s: `AXSelectionReader` reads `kAXSelectedTextAttribute` with no pasteboard, no privacy prompt, in about 1 ms. An empty or failed result falls through to `ClipboardSelectionReader` (⌘C inside a `ClipboardTransaction`).
- **Direction.** ru↔en, chosen by the dominant script.
- **Dismissal and cancellation.** `PanelController` reports dismissal and `TranslateAction` cancels its task. Pressing ⌃⌥T again cancels and restarts.
- **Availability.** On macOS < 26 the MVP has no engine, so Translate «Перевести» is disabled, with the hint "Needs macOS 26" «Нужна macOS 26». Phase 2 adds Ollama for older systems.
- **The MVP chain has one engine.** `FallbackTranslator` is already the seam, so Phase 2 only adds an engine to the list.

### 5.3 Permissions
```
Settings ▸ General (2b): the status is read when the window opens and whenever it becomes key
   (macOS 27 names the row Device Control and Data Access; the UI uses the running macOS's name)
   Grant Access…     ─► register the app (prompt API, literal key) + open Privacy ▸ Accessibility
   Reset Permission… ─► confirm ─► tccutil reset Accessibility com.smarttype.app (no admin password)
                                     ├─ exit 0 ─► relaunch ─► the new process asks and opens Settings,
                                     │    as SmartDock does: back in the list, switched off
                                     │    (the same process's request is only checked, never listed; tccd log)
                                     └─ failed ─► alert with the command to run in Terminal

⌃⌥L without the permission (2d) ─► alert: why SmartType needs it ─► Grant Access…
   menu shows "⚠︎ Grant Access…" until trusted — checked on menu open, never polled

pasteboard (macOS 15.4+): accessBehavior ─► .alwaysDeny, or types without data ─► don't borrow; alert:
                                          │    Privacy & Security ▸ Paste from Other Apps ▸ Allow
                                          └► .default / .ask ─► macOS asks on the first read
```

### 5.4 Context menu (macOS Services)
```
User        Front app (Cocoa)         macOS Services              SmartType
 │ right-click ─►│ Services ▸ "SmartType: Исправить раскладку"       │
 │               │─ selection ──────►│─ service pasteboard ─────────►│ fix(text) (Core)
 │               │◄─ replaces selection (native undo) ◄─ fixed text ─│ + switch layout
 │ right-click ─►│ Services ▸ "SmartType: Перевести"                 │
 │               │─ selection ──────►│──────────────────────────────►│ translate(text) → panel
```
- **Declaration.** Info.plist `NSServices` declares two services. Both include `NSRequiredContext` (empty); without it, macOS registers a service but doesn't show it.
  - `fixLayout` sends and returns `public.utf8-plain-text`; the returned text replaces the selection.
  - `translate` sends text only.
- **Why this path is cleaner** than the hotkey for the layout fix:
  - No clipboard, no ⌘C/⌘V, no Accessibility permission.
  - No pasteboard privacy prompt, because the service pasteboard isn't the general one.
  - Native undo.
  - It calls the same actions' text-based API.
- **Coverage.**
  - Works in apps that support Services: native Cocoa apps, Safari, Mail, Notes, Xcode, Pages.
  - Electron apps (VS Code, Slack…) usually don't show Services, so hotkeys remain the universal path.
  - Third-party apps can't add top-level items to other apps' context menus; Services is the system-sanctioned way.
- **Shortcuts.** We set no default `NSKeyEquivalent`: it allows ⌘ only and loses to the host app's own shortcuts. Users can bind their own in System Settings → Keyboard → Keyboard Shortcuts → Services.
- **Not offered yet: "Translate and replace".** Services are synchronous; translation is async.
- **Registration.** The app must be in /Applications. `make install` copies it there and refreshes the registry (`pbs -update`).

## 6. Domain model and correction algorithm
```
 ┌────────────────────────┐ provides ┌───────────────────────────────┐
 │ KeyboardLayoutProvider │ ───────► │ KeyboardLayout                │
 │  BuiltIn: US, RU-PC    │          │ id (TIS) · language ·         │
 │  Installed* (UCKey…)   │          │ output: [KeyStroke: String]   │
 └────────────────────────┘          └──────────────┬────────────────┘
                                                    │ layout pairs → LayoutConverter
                                                    ▼
 ┌────────────────────────┐   asks   ┌───────────────────────────────┐
 │ LanguageDetector       │ ◄─────── │ LayoutCorrector               │ ──► Correction
 │  script statistics     │          │ tokenize · decide · convert   │     text, targetLayoutID
 │  WordScorer chain:     │ ───────► │                               │
 │   Phonotactic          │  scores  └───────────────────────────────┘
 │   Dictionary           │
 │   LLM judge* (ties)    │          * later phases
 └────────────────────────┘          Plausibility: impossible < unknown < likely < known
```
```swift
package struct KeyStroke: Hashable, Sendable { package let keyCode: UInt16; package let shift: Bool }

package struct KeyboardLayout: Hashable, Sendable, Identifiable {
    package let id: String                          // TIS id, e.g. "com.apple.keylayout.RussianWin"
    package let language: Language
    package let output: [KeyStroke: String]         // what the writer means; some layouts type 2 characters
    package let alternatives: [String: KeyStroke]   // what macOS really types, where that differs
}

extension KeyboardLayout {                          // BuiltIn/RussianPC.swift — the whole file
    package static let russianPC = KeyboardLayout(id: "com.apple.keylayout.RussianWin", language: .russian,
        unshifted: "ё1234567890-=йцукенгшщзхъ\\фывапролджэячсмитьбю.",
        shifted:   "Ё!\"№;%:?*()_+ЙЦУКЕНГШЩЗХЪ/ФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,",
        alternatives: ["\u{00CB}": KeyStroke(keyCode: KeyStroke.ansiKeyCodes[0], shift: true)])  // measured: Shift+` types Latin Ë
}
```
```
selection ─► tokenize: words with attached punctuation; whitespace kept as is
               ([ ; ' , . count as word characters: they are х ж э б ю in Russian)
                 │
                 ▼
     all words come from ONE layout? ── yes ─► convert everything to the paired layout
                 │ no (mixed text)              (user intent; like Punto's "convert selection")
                 ▼
     per word: plausibility(original, own language) vs plausibility(converted, other language)
                 │
       converted wins? ── yes ─► replace the word         tie ─► keep it (LLM judge in Phase 2)
                 │
                 ▼
       nothing changed? ── yes ─► beep "nothing to fix"
```
- **Scorers available now:**
  - Phonotactic rules: impossible letter pairs (`jd`, `jn`, `fk`, `q` + consonant…; `щт`, `шы`, vowel + `ь`…) and impossible word starts (`yf`, `rf`, `vj`; `ь`, `ъ`, `ы`). English is measured on macOS's word list; Russian follows spelling rules.
  - The macOS dictionary (`NSSpellChecker`; en, ru, uk, he and ar ship with macOS). Without it, mixed text like «Привет, ghbdtn» is mostly undecidable.
- **Target layout.** `targetLayoutID` is the layout of the last converted word, because that's where the caret ends up and typing continues. When nothing would change, there is no correction at all.
- **Three or more layouts (Phase 3).** A word can then have several candidate conversions: the best reading wins, a whole selection goes to the layout whose language reads best, and ties go to the judge. A word counts only when exactly one layout could have typed it, so with Russian and Ukrainian both installed, «руддщ» (letters both layouts type) stays as it is; Phase 3 should try every layout that could have typed the word.
- **Isolation.** Core's data types are `Sendable`. `LanguageDetector` and `LayoutCorrector` hold injected scorers, so they run where those scorers live: the main actor, since `NSSpellChecker` is main-thread-only.
- **Detection module.** `LanguageDetector` is the separate detection module: its own folder and facade in Core, and it can become its own target when the LLM judge arrives.

## 7. Extension points (including future AI)
| Extension point | MVP (v0.1) | Later |
|---|---|---|
| `KeyboardLayoutProvider` | built-in US QWERTY, Russian – PC | the user's installed layouts via `UCKeyTranslate` (uk, he, ar…), rebuilt when the enabled sources change |
| `WordScorer` | phonotactic rules, macOS dictionary | LLM judge for ties (Phase 2) |
| `TranslationEngine` | Apple on-device (macOS 26+), Stage 3 | Ollama local LLM (Phase 2), others |
| `SelectionReader` | AX, then clipboard (Stages 3–4) | per-app strategies |
| Typing monitor | — | `CGEventTap` auto mode (Phase 3) |
| Entry points | hotkeys and the menu bar; Services (context menu) in Stage 4 | App Intents → Shortcuts and Spotlight actions (macOS 26) |
```
Phase 2
TranslateAction ─► FallbackTranslator ─► [Ollama · local LLM] ─► [Apple on-device] ─► error + reasons
                                          unavailable / failed ─┘   cancellation stops the chain
LayoutCorrector ─► LanguageDetector: phonotactic + dictionary ─► tie? ─► LLM judge ─► replace / keep

Phase 3 — auto mode
CGEventTap (listen-only, own thread) ── KeyStroke ──► WordBuffer ── word boundary ──► main actor
   LayoutCorrector.decide(word) ─┬─ keep
                                 ├─ replace ─► backspaces + Unicode typing (no clipboard)
                                 └─ ambiguous ─► LLM judge (async) ─► replace / keep
```

## 8. UI shell (AppKit + SwiftUI)
- **AppKit owns the shell.**
  - `LSUIElement` in Info.plist keeps the app out of the Dock. The code never calls `setActivationPolicy(.accessory)`: on SmartDock it could drop the status item at launch.
  - The menu bar is an `NSStatusItem` with an `NSMenu`.
  - `FloatingPanel` is an `NSPanel` with `[.nonactivatingPanel, .titled, .fullSizeContentView]`. It can become key without activating the app, and has native corners and shadow.
- **SwiftUI owns content.** Views are hosted by `NSHostingView` or `NSHostingController`, and their state lives in `@Observable` view models: the translation card's, and Settings' `AccessibilityViewModel`.
- **Menu** (English, with a Russian translation; ADR-014):
  - ⚠︎ Grant Access… «Разрешить доступ…», first, while Accessibility isn't granted.
  - Fix Layout ⌃⌥L «Исправить раскладку», and Translate ⌃⌥T «Перевести» (from Stage 3 disabled on macOS < 26).
  - Keyboard Shortcuts «Настройки хоткеев», a submenu showing the current bindings, and Settings… «Настройки…» ⌘,.
  - Quit SmartType «Выход».
- **Translation card:**
  - Header "RU → EN". The original is small (≤ 3 lines); the translation is large and selectable.
  - Footer: the engine that answered, plus why other engines were skipped; a Copy button (↩).
  - Liquid Glass on macOS 26+, `.regularMaterial` below.
- **Settings window** (2b): an AppKit window with SwiftUI content, laid out as SmartDock's: the app's icon, name, version and "Made with ❤ by Alex Karatai" on top, segmented tabs below.
  - General: the Accessibility status, under the name the running macOS gives it (Device Control and Data Access from macOS 27), with Grant Access… and Reset Permission….
  - Shortcuts: read-only until Phase 3 makes them editable.
  - About: version and build, what SmartType does, GitHub and Changelog links, "Made with ❤ by Alex Karatai".
  - `SettingsWindowController` builds the window when it opens and frees it, with its view model, when it closes; a test pins that nothing keeps them alive. Esc and ⌘W close it: an agent app has no main menu, so nothing else answers ⌘W, and the key is matched by key code, because with Russian – PC active it types "ц".
- **Panel behavior:**
  - Esc closes it via `cancelOperation`. A click outside closes it via resign-key, plus a mouse monitor that exists only while the panel is visible.
  - `PanelPlacement`, a pure and tested function, places it at the cursor and keeps it inside the screen's `visibleFrame`.
- **Why not `MenuBarExtra`:** no control over the status item, no non-activating panel, and opening Settings from an accessory app needs hacks.

## 9. Design patterns
| Pattern | Where | Why |
|---|---|---|
| Functional core, imperative shell | Core decides, App performs effects | the tricky logic is deterministic and unit-tested |
| Ports and adapters | protocols where they're consumed; macOS adapters in `System/` | C APIs (Carbon, TIS, AX, CGEvent) never leak into features |
| Composition root + constructor injection | `AppComposition` | one place knows the concrete types; no singletons, no service locator |
| Command | `AppCommand` from hotkeys and the menu | one routing point; future settings rebind commands, not code |
| Strategy | `TranslationEngine`, `WordScorer`, `KeyboardLayoutProvider`, `SelectionReader` | swap behavior without touching callers |
| Chain of responsibility | `FallbackTranslator`; selection readers (AX → clipboard) | ordered fallbacks that keep the reasons |
| Facade | `LanguageDetector` over the scorers; `ClipboardTransaction` over the pasteboard and keystrokes | callers make one intention-revealing call |
| Scoped transaction | `ClipboardTransaction.run { }` | the restore can't be forgotten; one owner of the clipboard at a time |
| MVVM + window controller | `TranslationViewModel` + `TranslationView` with `PanelController`; `AccessibilityViewModel` + Settings views with `SettingsWindowController` | SwiftUI renders state, AppKit owns windowing |

**Avoided on purpose:**
- singletons and global state;
- a "god" AppDelegate;
- NotificationCenter as an event bus;
- `DispatchQueue.main.async` sprinkled around (actors instead);
- a protocol around every class "for mocking" (calls that leave the process are injected parameters with real defaults instead; ADR-012);
- files of 1,000 lines.

## 10. Cross-cutting concerns
- **Dependency injection.** Everything is built in the composition root through initializers. The only singletons are system ones, each wrapped in one adapter. Protocols exist only at extension points.
- **Errors.**
  - Typed domain errors (`TranslationFailure.unavailable / .failed`, selection errors) become user-facing messages in the UI layer.
  - Cancellation is never shown as an error.
  - Failures of the layout fix are a beep, not a dialog.
- **Logging.** `os.Logger` with one category per subsystem: today general, hotkeys and permissions; selection and translation join with their stages. User text is never logged; any diagnostic value derived from it uses `privacy: .private`.
- **Testing.** Swift Testing, in three test targets:
  - Core: layouts round-trip, conversions, correction cases, scorers.
  - Engines: fake engines, the chain, cancellation.
  - App: the menu, the Settings window controller and its view models, `PanelPlacement`, and `PasteboardSnapshot` on a private `NSPasteboard`, so the user's clipboard is never touched. SwiftUI views hold no logic of their own and are verified live.

  Actions are tested with recorders injected at the process boundary (ADR-012); the real system calls are verified end to end.
- **Build.** The Makefile is the interface, mirroring SmartDock (see [CLAUDE.md](../CLAUDE.md#build--run)).
  - `make app` builds `build/SmartType.app` from `Resources/Info.plist`, which carries `LSUIElement`, `LSMinimumSystemVersion`, `CFBundleIconFile`, `CFBundleLocalizations [en, ru]`, from Stage 4 `NSServices`, and from Phase 2 `NSAllowsLocalNetworking`. It also compiles `Resources/Localizable.xcstrings` into `ru.lproj`, after `make l10n-check`.
  - `make run` opens the bundle; `make install` copies it to /Applications and runs `pbs -update`. `swift run` is not used: without the bundle there is no `LSUIElement`.
  - No SwiftPM resources. The generated `Bundle.module` looks for its bundle at the .app root (which breaks code signing) or at an absolute build path. So icons are SF Symbols, the app icon is generated by `scripts/generate-icon.swift` and copied in by `make app`, and translations are compiled from the String Catalog by `make app`.
- **Signing.**
  - Releases are ad-hoc signed, as SmartDock's are. With ad-hoc signing, macOS drops the Accessibility grant on every update.
  - Development builds are ad-hoc too (ADR-015). After a rebuild, Settings ▸ General ▸ Reset Permission restores the grant; `make app SIGN_ID="<identity>"` remains for a stable identity of your own, never a company's.
  - Hardened runtime and notarization come with a Developer ID (`make sign`).
  - From Stage 3, Translation.framework is weak-linked (checked with `otool`), so the app still launches on macOS 14.
- **Release.** `make bump` → tag → `release.yml` → GitHub Release → the Homebrew tap; see [DELIVERY.md](DELIVERY.md#release-and-distribution).

## 11. Decision log
| # | Decision | Why | Rejected alternative |
|---|---|---|---|
| 001 | AppKit shell, SwiftUI content | control over the status item, the non-activating panel and focus | a `MenuBarExtra`-only app |
| 002 | Modules by isolation domain | testable pure core; no access-modifier noise between main-actor parts | one target; per-feature modules; a separate System target |
| 003 | One data file per keyboard layout, keyed by physical key; pairs derived | adding uk/he/ar is one file each; same shape as `UCKeyTranslate` output and event-tap input | a protocol per language pair (as in the original spec) |
| 004 | Carbon `RegisterEventHotKey` | system-wide, needs no permission, zero idle cost | `CGEventTap` (needs Input Monitoring, always running) |
| 005 | Clipboard transaction for the hotkey layout fix | replaces exactly what was copied; works in every app; reliable undo | replacing text through AX (support and undo vary by app) |
| 006 | Read the selection through AX first for translation | no pasteboard prompt on macOS 27, no clipboard churn, ~1 ms | ⌘C only |
| 007 | Apple Translation via `TranslationSession(installedSource:target:)`, macOS 26+ | no coupling to UI; testable on current macOS | a SwiftUI `.translationTask` bridge for macOS 15 |
| 008 | Event-driven only | zero idle cost | timers, polling |
| 009 | Swift 6 strict concurrency, warnings as errors | data-race safety, a clean codebase | Swift 5 mode |
| 010 | Direct distribution (tentative) | the sandbox conflicts with synthetic input | the Mac App Store |
| 011 | Expose both commands as macOS Services | native right-click integration; the layout fix gets text in and out without the clipboard or Accessibility, with native undo | App Intents/Shortcuts only (needs user setup) |
| 012 | Seams at the process boundary: every call that leaves the process is a parameter whose default is the real thing | actions are unit-tested with recorders and no test touches the real clipboard or input source; proven on SmartDock, where an unseamed modal alert hung the suite | a protocol around every class; actions tested only end to end |
| 013 | Makefile-driven release: `make bump` → tag → GitHub Release → Homebrew tap (cask + formula) | the same pipeline as SmartDock; the version lives in one place and release notes cannot be empty | a hand-rolled bundle script; manual tap updates |
| 014 | The interface is English with a Russian translation and follows the language of macOS. Strings are `String(localized:)` with English keys, kept in a String Catalog that `make app` compiles; `make l10n-check` fails on a missing translation | the audience is wider than Russian speakers, and adding languages later is one catalog column. A missing translation cannot ship | Russian only, as in the original spec; English only; SwiftPM resources (`Bundle.module` breaks signing) |
| 015 | Development builds are ad-hoc signed, like releases; Reset Permission (`tccutil`) recovers the Accessibility grant after a rebuild | the only Apple Development certificates on the dev machine belong to other teams and expire on 2026-10-20; a lost grant is restored from Settings: confirm the reset, SmartType restarts, switch it back on | signing with a company's certificate; a self-signed local certificate (revisit if re-granting becomes a burden) |

## Appendix — File layout
The target layout, including files later stages add. What exists today is CLAUDE.md's file table, which `make docs-check` keeps exact.
```
Package.swift · Makefile · .swift-format · README.md · CHANGELOG.md · CONTRIBUTING.md · CLAUDE.md
Resources/{Info.plist, Localizable.xcstrings} · scripts/{docs-check.swift, l10n-check.swift, generate-icon.swift} · assets/ (README images)
.github/{workflows/ci.yml, workflows/release.yml, dependabot.yml, pull_request_template.md, ISSUE_TEMPLATE/}
docs/BUSINESS.md · docs/ARCHITECTURE.md · docs/DELIVERY.md
Sources/SmartTypeCore/
  Language/{Language, Script}
  Layouts/{KeyStroke, KeyboardLayout, KeyboardLayoutProvider, LayoutConverter}
  Layouts/BuiltIn/{USQwerty, RussianPC}
  Detection/{Plausibility, WordScorer, LanguageProfile, PhonotacticScorer, LanguageDetector}
  Detection/Profiles/{English, Russian}
  Correction/{LayoutTokenizer, LayoutCorrector, Correction}
Sources/SmartTypeEngines/
  {TranslationEngine, TranslationFailure, FallbackTranslator}
  Apple/AppleTranslationEngine
  (Phase 2: HTTPTransport, Ollama/{OllamaClient, OllamaChatDTO, OllamaTranslationEngine, TranslationPrompt})
Sources/SmartTypeApp/
  App/{AppDelegate, AppComposition, AppCommand, AppRelauncher, Log}
  StatusBar/{StatusBarController, StatusMenu, NSMenuItem+Handler}
  ContextMenu/TextServiceProvider
  Actions/{LayoutFixAction, TranslateAction}
  Panel/{FloatingPanel, PanelController, PanelPlacement, TranslationViewModel, TranslationView}
  Permissions/{AccessibilityPermission, Onboarding}
  Settings/{SettingsWindowController, SettingsWindow, SettingsView, GeneralView, ShortcutsView, AboutView,
            AccessibilityViewModel, AppInfo}
  System/HotKeys/{KeyCombo, HotKeyCenter, CarbonHotKeyRegistrar}
  System/Keyboard/{KeystrokeSender, InputSourceSwitcher}
  System/Selection/{SelectionReader, AXSelectionReader, ClipboardSelectionReader,
                    ClipboardTransaction, PasteboardSnapshot}
  System/Spelling/SpellCheckScorer
Sources/SmartType/main.swift
Tests/{SmartTypeCoreTests, SmartTypeEnginesTests, SmartTypeAppTests}
```
