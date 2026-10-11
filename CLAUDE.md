# CLAUDE.md

Project instructions for Claude Code. Follow these exactly.

SmartType is a macOS menu-bar assistant. ⌃⌥L fixes text typed in the wrong keyboard layout; ⌃⌥T translates the selection in a floating panel; both commands are also macOS Services in the right-click menu.

The design lives in `docs/`: [business](docs/BUSINESS.md), [architecture](docs/ARCHITECTURE.md), [delivery](docs/DELIVERY.md). This file is *how* the work is done; the architecture is *what* is built. When the two disagree, reconcile them before writing code.

The conventions mirror SmartDock (`~/work/smartdock`), the author's other menu-bar app: the same process, the same Makefile-driven release and the same Homebrew tap. A lesson carried over from there is marked *(SmartDock)*.

## Working on a Task

One task at a time, carried through these steps in order. A step is not done because it was started; each has a visible output. The tree ends up ready for the **user** to commit and release; see the last step.

### 0. Before a stage starts

A stage of [DELIVERY.md](docs/DELIVERY.md) starts only when all of these hold. If one does not, say which:
- The previous stage is committed, its CI run is green, and the user confirmed its manual checklist.
- The working tree is clean.
- Every open question in [BUSINESS.md §11](docs/BUSINESS.md#11-open-questions-for-review) that changes this stage's scope has an answer. Stage 3, for example, depends on questions 1, 2 and 6.
- The stage row and the [ARCHITECTURE.md](docs/ARCHITECTURE.md) sections it touches have just been read again, not recalled.

### 1. Understand the task

Restate it: what changes for a person, what is in scope, and what is explicitly not. If two readings would lead to different work, ask now. Work from a later stage waits for the user's go-ahead.

### 2. Measure before planning

Everything load-bearing is checked against the running system before it reaches a plan; a plan built on an assumption is worth nothing. Facts in this project that were measured, not recalled:
- The macOS 27 SDK says the general pasteboard *asks* the user on programmatic reads (`NSPasteboard.h`, `NSPasteboardAccessBehavior`).
- `TranslationSession(installedSource:target:)` exists from macOS 26, and the session type is not `Sendable` (Translation's `.swiftinterface`).
- The user's enabled keyboard layouts are `com.apple.keylayout.US` (`en`) and `com.apple.keylayout.RussianWin` (`ru`), read from the TIS input-source list.

State plainly which claims are measured and which are knowledge. "I believe" and "I checked" are different words; never let one stand in for the other.

### 3. Plan

What the change is, which files it touches, what could break, and what stays out of scope. Where there is a real choice, give options with a recommendation, not a survey.

**Acceptance first.** Where the spec or [DELIVERY.md](docs/DELIVERY.md) names an expected result (`yfgbcfk` → `написал`), it becomes a test before the code that makes it pass.

### 4. Challenge the plan, then get a decision

Before writing code, attack the plan:
- What did it assume?
- Which call sites does it not mention?
- What would a user see that they did not ask for?

Revise it. Then wait for a decision on anything that changes behaviour users rely on or departs from [ARCHITECTURE.md](docs/ARCHITECTURE.md). A departure is recorded there as an ADR.

Steps 1–4 end in one visible **brief**, shown before any code is written:

| Brief | Content |
|---|---|
| Task | the restatement; in scope; out of scope |
| Measured | the facts checked for this plan, and how |
| Plan | the files to add or change; what could break |
| Acceptance | the tests that will prove it, and the manual checks |
| Challenge | assumptions, unmentioned call sites, anything a user would see that they did not ask for |
| Decision | "none needed", or the question for the user |

### 5. Implement — to the plan

The acceptance tests come first: they fail for the right reason, then the code makes them pass. Match the surrounding code. Prefer a structural fix over a patch; see **A list repeated in two places will drift** under Principles. Note every deviation from the plan as it happens; don't reconstruct it afterwards.

### 6. Reconcile with the plan

Read the plan against the diff and answer three questions explicitly:
- Planned and done.
- Planned and **not** done, and why.
- Done and **not** planned, and why.

The third group is where unreviewed behaviour hides.

### 7. Review the diff

Read the whole diff the way a reviewer would, against Code Style and Principles:
- Files stay ≲ 150 lines and functions under ~40.
- Names make comments unnecessary; the comments that remain say *why*.
- Access is `private` by default and `package` across targets.
- Every call that leaves the process sits behind a seam.
- No user text reaches a log.
- Nothing is left over from debugging.

### 8. Regressions, compatibility and live checks

Green tests are the floor, not the ceiling. Read every call site the change touches and ask what silently behaves differently now. Check compatibility on three axes:
- **Stored data:** UserDefaults written by earlier versions.
- **Toolchains:** CI runs Xcode 26.x, the dev machine Xcode 27 (see Gotchas).
- **Frozen contracts:** Services `NSMessage` names and menu titles, because users bind shortcuts to them in System Settings, and the `KeyCombo` storage format.

Where tests cannot reach, verify live: `make run`, read the unified log with `/usr/bin/log` (zsh shadows the name), and exercise the feature in TextEdit.

**When Claude cannot drive the UI** (macOS refuses synthetic keystrokes from a process without Accessibility):
1. Claude writes a numbered manual checklist with the expected result of each step.
2. The user runs it.
3. Claude confirms from the log whatever the log can show.

The stage is not done until the user has confirmed the checklist.

Then put the machine back: quit the test build, and restore the clipboard and the input source you changed.

### 9. Tests

In this order:
1. The suite passes.
2. Anything broken is fixed, not skipped.
3. New logic in `SmartTypeCore` gets tests.
4. A new guard is proven by **mutation**: break it, watch the intended test fail, restore, re-run. A fixture that leaves a field at its default cannot catch that field being dropped.

The `SmartType` executable (`main.swift` only) is outside the test bundle. Say so rather than implying coverage, and verify it by running.

### 10. Final consistency pass

Nothing ships while any two of these disagree: the code, this file, `docs/`, `CHANGELOG.md`, `README.md`, the diff's comments.
- Every make target that does not change the machine runs — all of them *(SmartDock: `make coverage` broke on a new Xcode while `swift test` passed)*. `install` and `fix` write to /Applications; run them only when the stage is about them.
- `make docs-check` passes: every link and anchor resolves, and the file table below lists exactly the files under `Sources/`.
- No document still describes the old behaviour, and every symbol a document names exists.
- The CHANGELOG entry sits under `## [Unreleased]` and says what changed for a person and why.

### 11. Stop at the commit

**Claude does not commit, push, tag or release.** Leave the working tree ready and report, in this order:
- the reconciliation from step 6;
- what is in the tree, file by file;
- suggested commit subjects.

Never add a `Co-Authored-By` trailer. Bumping, committing, tagging and releasing are the user's, one task per version, so a release traces to a single change.

### Definition of Done (a stage)

- [ ] `make lint`, `make test` (new guards proven by mutation), `make coverage` (read, not just run), `make app` — and every other target that does not change the machine.
- [ ] `make docs-check` passes. The CHANGELOG, the file table and `docs/` describe what was built.
- [ ] The live check is done and the user has confirmed the manual checklist; the machine is put back.
- [ ] When the stage changed what runs, the idle cost is re-measured with `make footprint` against [ARCHITECTURE.md §1](docs/ARCHITECTURE.md#1-goals-and-quality-attributes).
- [ ] The reconciliation and file-by-file report are given, and the user has committed.
- [ ] CI is green on `dev`.

## Principles

The rules this codebase runs on. Each carries its reason, so the reason survives the next refactor. A change that breaks one is a change to the design: record it as an ADR in [ARCHITECTURE.md](docs/ARCHITECTURE.md).

**One execution path.** Hotkeys, the menu and macOS Services are front doors into one core operation per action: `LayoutFixAction.fix(text)` and `TranslateAction.translate(text)`. A new input adds a door, not a behaviour. *(SmartDock: four front doors, one `performCommand`.)*

**The clipboard is borrowed, never taken.**
- `ClipboardTransaction` snapshots every item and type, does its work, and restores the snapshot only if `changeCount` is still its own. A user who copied something in the meantime keeps it.
- Writes carry `org.nspasteboard.TransientType` and `AutoGeneratedType`, so clipboard managers skip them.
- Stale content is never used: no `changeCount` bump after ⌘C means nothing was selected.

**Nothing the system reports is taken on trust.**
- An AX selection can be empty or stale, so fall through to the next reader.
- A synthetic ⌘C may not land, so check `changeCount`.
- A translation in the wrong script is a failure, not a result.

*(SmartDock: `NSAppleScript` reported success for a change macOS had refused.)*

**Release the keys before pressing others.** The hotkey fires while ⌃⌥ are still held, so a synthetic ⌘C sent at that moment arrives as ⌃⌥⌘C and does nothing. Wait until the physical modifiers are released (10 ms steps, ≤ 1 s), then post with explicit flags. Explicit flags alone are not enough; Espanso and Sorla measured the same.

**Zero idle cost.** No timers, polling or event taps while idle; only Carbon hotkeys and AppKit events wake the app. A bounded wait is allowed only inside an action the user started. Anything else needs an ADR.

**Text stays private.** User text never leaves the Mac (the Phase 2 LLM is local too) and is never logged. A diagnostic derived from it uses `privacy: .private`.

**A layout is data, not code.** Each keyboard layout is one file holding two 47-character strings in ANSI key order, and language pairs are derived from them. Tests pin every layout's length, uniqueness and round trip, so a typo fails the build instead of a user's sentence.

**Break the build rather than write a note.** Where the compiler can reach, agreement between two places is enforced by an exhaustive switch (`AppCommand` → title, default hotkey, menu item, action). Where it cannot, a test or make target enforces it (Services in `Info.plist` ↔ `TextServiceProvider` selectors). *(SmartDock.)*

**A list repeated in two places will drift.** Commands, hotkeys, menu items and services come from one `AppCommand` list; layouts come from one provider. Drive code from `allCases` with an exhaustive switch rather than a hand-written list. *(SmartDock: a hand-written backfill drifted to five of its ten settings.)*

## Build & Run

The Makefile is the interface, mirroring SmartDock. The release targets (`changelog-check`, `release-notes`, `release`) join it in Stage 5 of [DELIVERY.md](docs/DELIVERY.md).

```bash
make build / test / app / run / clean         # swift build -c release · swift test · bundle (ad-hoc) · open · clean
make format / lint / coverage                 # swift-format apply · check (CI gates) · llvm-cov table
make bump V=1.2.3 / version-check / release   # version everywhere · verify refs · build + zip + gh release
make changelog-check / release-notes          # this version's notes exist · print them (the release body)
make install / fix                            # copy to /Applications + refresh Services · xattr -cr + codesign
make docs-check / footprint                   # links, anchors, file table · idle CPU, wakeups, memory of the running app
make l10n / l10n-check                        # add new UI strings to the catalog · every string used and translated
make doctor / logs / actions-check            # environment check · live log · Actions vs latest
swift test --filter <testName>                # one test
```

Builds are ad-hoc signed, for development as for releases (ADR-015), so macOS drops the Accessibility grant after every rebuild. From Stage 2b, the menu's «Reset Permission…» restores it. `make app SIGN_ID="<identity>"` signs with a stable identity of your own, never with a company's certificate.

## Version & Release

**Never edit a version by hand — always `make bump V=x.y.z`.** The version is written in four places, and `bump` is the only thing that knows all of them; `version-check` fails if any reference is stale:
- the `Makefile` (source of truth);
- `Resources/Info.plist` (`CFBundleShortVersionString`, and `CFBundleVersion` +1);
- the README badge (URL and alt text);
- a dated section in `CHANGELOG.md`.

Before the first release, `VERSION` is the version being built (`0.1.0`) and the CHANGELOG has no dated section yet. `version-check` reports that state as *unreleased* instead of failing, and the first `make bump V=0.1.0` opens the section.

**Never delete `## [Unreleased]`.** `bump` opens the new section directly under it, so whatever accumulated there becomes the release notes. `changelog-check` refuses a release whose notes are empty; both `make release` and `release.yml` call it. *(SmartDock shipped two releases with empty notes before the check sat on both paths.)*

**Releasing is the user's step:** `make bump V=x.y.z` → fill in the notes → commit → tag `vX.Y.Z` → push the tag. `release.yml` then runs:
1. 🧪 Test.
2. 🔨 Build: `make bump`, `changelog-check`, `release-notes`, `make app`, zip.
3. 🎉 GitHub Release, with the CHANGELOG section as its body.
4. 🍺 Homebrew. Over SSH with the `TAP_DEPLOY_KEY` secret, it updates `Casks/smarttype.rb` (zip + sha256) and `Formula/smarttype.rb` (source tarball + sha256) in `alexeikaratai/homebrew-tap`. It fails if a `sed` matched nothing.

**Before the first release:**
- Homebrew cannot download release assets of a **private** repository, so the repository must be public by then.
- The deploy key and the tap's two files are created once, by hand.

## CI/CD

`ci.yml` and `dependabot.yml` land with Stage 1; `release.yml` lands with the first release (Stage 5).
- **`ci.yml`** (push to `main`/`dev`, PRs to `main`, and manual runs):
  - Concurrency per branch, read-only permissions, SPM cache.
  - Then `version-check` → `docs-check` → `l10n-check` → `lint` → `coverage` → `swift build -c release` → `make app` + `codesign --verify --strict`.
  - Lint runs first, so a formatting PR fails in seconds.
- **`release.yml`** (a `v*` tag): as above.
- **`dependabot.yml`**: monthly grouped Actions bumps. There is no `swift` entry, because there are no SPM dependencies.

Xcode is set through `env.XCODE_PATH` at workflow level, never inline. The runner and `XCODE_PATH` must agree, so check the runner image readme before bumping either. Actions are pinned by major version; `make actions-check` compares them to the latest.

## Known Build Gotchas

Carried over from SmartDock; they apply to any SwiftPM app built on this machine.

- **CI cannot follow the dev machine.**
  - No `macos-27` runner exists, and `macos-26` stops at Xcode 26.x, while the dev machine runs Xcode 27 / Swift 6.4. Code and tests must compile on both.
  - Avoid Swift 6.4-only features.
  - Never give a local the name of a function in scope: the older compiler misresolves it inside macros such as `#require`.
  - A green local suite is not proof; the next CI run is.
- **SPM's output layout moved in Swift 6.4.**
  - `.build/release` becomes a symlink into `out/Products/Release`, modules are bundle directories, and the test bundle is named after the target.
  - Anything that reaches into `.build` by path must handle both layouts.
  - Recipes run under `set -e`.
  - When a toolchain changes, run every make target.
- **`swift-format` in Xcode 27 requires `orderedImports.shouldGroupImports`** in `.swift-format`. Set it to `true`; the Xcode 26 formatter ignores it.
- **A workflow step creates what it writes into** (`mkdir -p build`). A developer's machine always has leftovers that a fresh runner does not.
- **Stale build after changing an initialiser used as a default argument.** The link fails with `Undefined symbols`; run `rm -rf .build && swift build`.
- **macOS 26 draws no `NSMenuItem.image` in a status menu.** If menu items need icons, put the SF Symbol as an `NSTextAttachment` in `attributedTitle` and align with a tab stop.
- **`open` can hand a launch to an app that is already gone.** For a short while after the process exits, LaunchServices still treats the app as running, so a plain `open` "activates" it and nothing starts. Measured: one launch in three failed, even after waiting for the process to exit. `make run` stops the old instance, waits for it, and then uses `open -n`.
- **Never call `setActivationPolicy(.accessory)`.** It can drop the status item at launch. `LSUIElement` in `Info.plist` is the only switch, so run the app through `make run`, not `swift run`.

## Architecture

[ARCHITECTURE.md](docs/ARCHITECTURE.md) is the source of truth for modules, flows, patterns and ADRs. Modules are split by isolation domain:
- `SmartTypeCore`: pure logic, nonisolated.
- `SmartTypeEngines`: nonisolated async.
- `SmartTypeApp`: `@MainActor` by default.
- `SmartType`: the executable, holding only `main.swift`.

Swift Package tools 6.2, macOS 14+, Swift 6 strict concurrency, zero dependencies.

Keep this table current, as SmartDock does: one row per file, including the measured facts that file depends on. Paths are relative to `Sources/`. `make docs-check` fails when a file has no row, or a row has no file.

| File | Responsibility |
|---|---|
| `SmartTypeCore/Language/Language.swift` | A language: BCP 47 code and script (`.english`, `.russian`). |
| `SmartTypeCore/Language/Script.swift` | The script of a letter, by Unicode block. Latin covers U+00C0–U+024F, so the "Ë" macOS types counts as Latin. |
| `SmartTypeCore/Layouts/KeyStroke.swift` | A physical key, with or without Shift. `ansiKeyCodes` lists the 47 ANSI keys row by row, pinned to Carbon's `kVK_ANSI_*` by `ANSIKeyCodeTests`. |
| `SmartTypeCore/Layouts/KeyboardLayout.swift` | One layout: TIS ID, language, the output of each key, and `alternatives` for what macOS really types when that differs. |
| `SmartTypeCore/Layouts/BuiltIn/USQwerty.swift` | U.S.: 94 characters, measured with `UCKeyTranslate`. |
| `SmartTypeCore/Layouts/BuiltIn/RussianPC.swift` | Russian – PC, measured with `UCKeyTranslate`. Shift+` types Latin "Ë" (U+00CB): the table says Cyrillic "Ё" (U+0401) and keeps "Ë" as an alternative. |
| `SmartTypeCore/Layouts/KeyboardLayoutProvider.swift` | Where layouts come from: `BuiltInLayouts` now, the user's installed layouts in Phase 3. |
| `SmartTypeCore/Layouts/LayoutConverter.swift` | Retypes text from one layout into another. Longest match first, for keys that type several characters; text no key types passes through. |
| `SmartTypeCore/Detection/Plausibility.swift` | `impossible < unknown < likely < known`. |
| `SmartTypeCore/Detection/WordScorer.swift` | One opinion on a word. Not `Sendable`, because a scorer may wrap a main-thread service. |
| `SmartTypeCore/Detection/LanguageProfile.swift` | Data: the pairs and starts a language never uses. |
| `SmartTypeCore/Detection/Profiles/English.swift` | Measured on `/usr/share/dict/words` (210,773 lowercase entries): 127 pairs in at most 5 entries, and 334 starts in none. Regenerated, never edited by hand. |
| `SmartTypeCore/Detection/Profiles/Russian.swift` | Spelling rules, because macOS ships no Russian word list. жю and шю are allowed, for жюри and брошюра. |
| `SmartTypeCore/Detection/PhonotacticScorer.swift` | `.impossible` on a forbidden start or pair, `.unknown` otherwise. |
| `SmartTypeCore/Detection/LanguageDetector.swift` | The detection module: the dominant language by script (the translation direction), and a word's plausibility from the scorers. `known` beats `impossible`; otherwise the most pessimistic opinion wins. |
| `SmartTypeCore/Correction/LayoutTokenizer.swift` | Words (runs of non-whitespace, punctuation attached) and whitespace, in one pass. |
| `SmartTypeCore/Correction/LayoutCorrector.swift` | A word's source is the only layout that could have typed it. One source for the whole selection: convert it whole. Mixed sources: decide word by word, and a tie keeps the word. The target is the layout of the last converted word. |
| `SmartTypeCore/Correction/Correction.swift` | The fixed text and the layout to switch to. |
| `SmartType/main.swift` | Entry point: `NSApplication` plus a top-level `AppDelegate`. `delegate` is weak, so the top-level constant is what keeps it alive. No `setActivationPolicy`; `LSUIElement` lives in `Resources/Info.plist`. |
| `SmartTypeApp/App/AppDelegate.swift` | Builds `AppComposition` in `applicationDidFinishLaunching`. |
| `SmartTypeApp/App/AppComposition.swift` | Composition root. Registers every `AppCommand`'s default hotkey, collects refusals for the menu, and owns `perform(_:)`, the single entry point for every command (Stage 1: logs only). `stop()` lets a test take its status item down. |
| `SmartTypeApp/App/AppCommand.swift` | The list of commands: a localized title and a default hotkey, both through exhaustive switches. A `nonisolated` value type. |
| `SmartTypeApp/App/Log.swift` | `Logger`s under `com.smarttype.app` (`general`, `hotkeys`). `nonisolated`, so code with any isolation can log. Every file that logs imports `OSLog` itself; `MemberImportVisibility` rejects the transitive import (measured). |
| `SmartTypeApp/StatusBar/StatusBarController.swift` | Owns the `NSStatusItem`, whose SF Symbol `character.cursor.ibeam` is pinned by a test. Refills the menu in `menuNeedsUpdate`, so nothing runs between openings. |
| `SmartTypeApp/StatusBar/StatusMenu.swift` | Builds the menu from `AppCommand.allCases`: one item per command with its key equivalent, the read-only «Настройки хоткеев» submenu (refused combinations marked), and «Выход» ⌘Q. |
| `SmartTypeApp/StatusBar/NSMenuItem+Handler.swift` | Closure-based menu items: a convenience init and a private `MenuAction` target, kept alive by `representedObject` because `target` is weak. Not a subclass: the SDK's `NSMenuItem` designated initializers are nonisolated, and overriding them from this main-actor module does not compile (measured). |
| `SmartTypeApp/System/HotKeys/KeyCombo.swift` | `KeyCombo`, `Key` and `Modifiers`: physical key codes, the display string (⌃⌥L), Carbon flags and `NSEvent.ModifierFlags`, all three derived from one table. `Codable`, for the future settings window. |
| `SmartTypeApp/System/HotKeys/HotKeyCenter.swift` | `HotKeyRegistering` (the seam) and `HotKeyCenter`: identifiers and actions. A refused combination never keeps an action; this guard is proven by mutation. |
| `SmartTypeApp/System/HotKeys/CarbonHotKeyRegistrar.swift` | The real implementation behind the seam: `RegisterEventHotKey`, one event handler, the signature `SMTY`. The C callback is `nonisolated` and hands the identifier back through `MainActor.assumeIsolated`. `deinit` tears down through `nonisolated(unsafe)` storage. Not covered by tests; verified live. |

## Code Style

`swift-format` is authoritative, with the same configuration as SmartDock: `.swift-format`, `make format` / `make lint`, reached through `xcrun swift-format`. Beyond the formatter:

- **Names.** `UpperCamelCase` for types, `lowerCamelCase` for everything else, constants included. Protocols end in `-ing`/`-able`. Bools read as assertions (`isTrusted`, `hasSelection`). Abbreviations keep Apple's casing (`layoutID`, `URL`).
- **Layout.** `// MARK: -` sections; properties → init → API → private; protocol conformances in extensions at the bottom. One primary type per file (small companion types allowed). Files ≲ 150 lines, functions under ~40.
- **Access.** `private` by default and `internal` never written out. Cross-target API is `package`, never `public`. `final` on every class.
- **Values.** `struct` and `let` unless there is a reason; a caseless `enum` for namespaces. Force unwraps only for AppKit objects set right after init. No `Any`.
- **Control flow.** `guard` + early return; `[weak self]` + `guard let self` in escaping closures; default parameters over overloads; `lazy var` for expensive one-time setup.
- **Comments.** Names over comments. A comment says *why*, never *what*. Doc comments go on cross-target API.
- **Seams at the process boundary.** Every call that leaves the process goes through a parameter (protocol or closure) whose default is the real thing: CGEvent posting, the general pasteboard, TIS, AX, `NSWorkspace.open`, `AXIsProcessTrustedWithOptions`, `NSSpellChecker`, Translation, `NSAlert`. The app passes nothing; a test passes a recorder. *(SmartDock: an unseamed modal alert hangs the whole test suite.)*
- **Logging.** Through `Log`, never `print()`.

## Testing

Swift Testing (`@Suite`, `@Test`, `#expect`), with suites running in parallel.

- Logic lives in `SmartTypeCore` whenever it can, and is covered there: every layout, every conversion and correction case, every scorer rule.
- Actions are tested with recorders at the process boundary; the real system calls are verified live (step 8).
- Tests never touch the user's clipboard, input source or Accessibility state. Use a private `NSPasteboard(name:)`, an injected input-source switcher and an injected trust check.
- Acceptance tests from the spec are written before the code that makes them pass (step 5).
- A test that waits for the main queue waits for the event (a `waitUntil` helper), never for a fixed time.
- A suite that triggers menu actions creates `NSApplication.shared` in its `init`. `performActionForItem` sends the action through `NSApp`, and without it a test passed or failed depending on which suite happened to run first (measured with a mutation).
- A new guard is proven by mutation (step 9).
- Fakes live in each test target's `Mocks.swift`, and helpers such as `waitUntil` in `TestSupport.swift`, created when the first helper is needed. This mirrors SmartDock.

## Conventions

**Concurrency.**
- Swift 6 language mode. `SmartTypeApp` has `defaultIsolation(MainActor)`; Core is nonisolated, with `Sendable` data types.
- No `Task.detached`.
- Carbon and Services callbacks arrive on the main thread; assert this with `MainActor.assumeIsolated`.
- Cancellation flows from the UI down to the engines.

**AppKit.** Programmatic UI, no nibs. SwiftUI only as content inside AppKit windows (`NSHostingController`). `LSUIElement = true`. SF Symbols, and no SwiftPM resources (they break bundle signing).

**Hotkeys.** Carbon `RegisterEventHotKey`, with ⌃⌥ defaults. Require ⌃ or ⌘ in a combination, because some macOS 15 builds reject combinations made only of ⌥ or ⌥⇧. Carbon reports no conflict with other apps' hotkeys.

**Accessibility & TCC.** Ad-hoc signing changes the code hash on every build, and macOS silently drops the grant. Re-grant it with «Reset Permission…» (from Stage 2b), or run `tccutil reset Accessibility com.smarttype.app`. On macOS 27 that command needs no administrator password; this was measured while no entry existed, so measure again once one does. The prompt key is the literal `"AXTrustedCheckOptionPrompt"`: the C constant is imported as a `var`, which Swift 6 rejects.

**Localization.**
- The interface is English with a Russian translation, and follows the language of macOS. A person can pick a language per app in System Settings → General → Language & Region → Applications.
- Every UI string is `String(localized: "English text", comment: "where it appears")`. The English text is the key; keys are plain literals. Compose with code (a title plus a shortcut) rather than interpolating inside a key.
- Translations live in `Resources/Localizable.xcstrings`. `make l10n` adds new keys (Apple's `xcstringstool extract` + `sync`); then translate them into Russian.
- `make l10n-check` fails on a key that is not a plain literal, a key missing from the catalog, a stale key or a missing Russian value. `make app` runs it first and compiles the catalog into `ru.lproj`.
- The check reads the sources itself instead of calling `xcstringstool extract`. Measured on Xcode 27; whether Xcode 26.6 on CI has `extract` was not confirmed, so the check depends on nothing beyond Swift.
- The bundle has no `en.lproj` and needs none. The English strings are the keys, and `CFBundleLocalizations [en, ru]` with development region `en` make English selectable. Measured with `Bundle.preferredLocalizations`: `en-US` first resolves to English, `ru` first to Russian, `de-DE` falls back to English.
- Tests run without the app bundle, so they see the English keys.
- Services titles (Stage 4) need their own `ServicesMenu.strings`.

**Identifiers.** The bundle ID and log subsystem are both `com.smarttype.app`. UserDefaults keys live under `com.smarttype.`.

**Logging.** `Log` (a `Logger` with subsystem `com.smarttype.app`). Record at **notice** or above, since `.info` and `.debug` are not persisted and are invisible to `log show`.

## Entitlements & Permissions

- **Sandbox:** off, because the app sends synthetic input and Services into other apps.
- **Signing:** ad-hoc builds carry no entitlements file. Hardened runtime comes only with a Developer ID (`make sign`, later).
- **Accessibility:** needed to post ⌘C/⌘V and to read the selection through AX.
- **Pasteboard access (macOS 15.4+):** the hotkey layout fix reads the general pasteboard; Services and AX reading do not.
- **Apple engine:** translation languages must be installed (System Settings → General → Language & Region → Translation Languages).
