# CLAUDE.md

Project instructions for Claude Code. Follow these exactly.

SmartType is a macOS menu-bar assistant. ⌃⌥⇧L fixes text typed in the wrong keyboard layout; ⌃⌥⇧T translates the selection in a floating panel; a person can set other shortcuts in Settings, and both commands are also macOS Services in the right-click menu.

The design lives in `docs/`: `BUSINESS.md`, `ARCHITECTURE.md` and `DELIVERY.md`. It is the private repository `alexeikaratai/smarttype-docs`, cloned into `docs/` and ignored here, so this file names it by path, never by link: the public repository and CI do not have it. This file is *how* the work is done; the architecture is *what* is built. When the two disagree, reconcile them before writing code.

The conventions mirror SmartDock (`~/work/smartdock`), the author's other menu-bar app: the same process, the same Makefile-driven release and the same Homebrew tap. A lesson carried over from there is marked *(SmartDock)*.

## Working on a Task

One task at a time, carried through these steps in order. A step is not done because it was started; each has a visible output. The tree ends up ready for the **user** to commit and release; see the last step.

### 0. Before a stage starts

A stage of `docs/DELIVERY.md` starts only when all of these hold. If one does not, say which:
- The previous stage is committed, its CI run is green, and the user confirmed its manual checklist.
- The working tree is clean.
- Every open question in `docs/BUSINESS.md` §11 that changes this stage's scope has an answer. Stage 3, for example, depends on questions 1, 2 and 6.
- The stage row and the `docs/ARCHITECTURE.md` sections it touches have just been read again, not recalled.

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

**Acceptance first.** Where the spec or `docs/DELIVERY.md` names an expected result (`yfgbcfk` → `написал`), it becomes a test before the code that makes it pass.

### 4. Challenge the plan, then get a decision

Before writing code, attack the plan:
- What did it assume?
- Which call sites does it not mention?
- What would a user see that they did not ask for?

Revise it. Then wait for a decision on anything that changes behaviour users rely on or departs from `docs/ARCHITECTURE.md`. A departure is recorded there as an ADR.

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
- [ ] When the stage changed what runs, the idle cost is re-measured with `make footprint` against `docs/ARCHITECTURE.md` §1.
- [ ] The reconciliation and file-by-file report are given, and the user has committed.
- [ ] CI is green on `dev`.

## Principles

The rules this codebase runs on. Each carries its reason, so the reason survives the next refactor. A change that breaks one is a change to the design: record it as an ADR in `docs/ARCHITECTURE.md`.

**One execution path.** Hotkeys, the menu and macOS Services are front doors into one core operation per action: `LayoutFixAction.fix(text)` and `TranslateAction.translate(text)`. A new input adds a door, not a behaviour. *(SmartDock: four front doors, one `performCommand`.)*

**The clipboard is borrowed, never taken.**
- `ClipboardTransaction` snapshots every item and type, does its work, and restores the snapshot only if `changeCount` is still its own. A user who copied something in the meantime keeps it.
- Writes carry `org.nspasteboard.TransientType` and `AutoGeneratedType`, so clipboard managers skip them.
- Stale content is never used: no `changeCount` bump after ⌘C means nothing was selected.
- One owner at a time: both commands share one transaction, and one started while the other has the clipboard beeps. Otherwise it would snapshot the text SmartType had just pasted and give that back, and the person's clipboard was lost (reproduced in a test).

**Nothing the system reports is taken on trust.**
- A selection Accessibility reports may be stale, so the layout fix, which replaces it, still copies it with ⌘C; Translate only shows it. No answer falls through to ⌘C. "Nothing is selected" is believed, because ⌘C would then make the app beep a second time, or copy the whole line in VS Code (measured: VS Code's empty answer is true).
- A synthetic ⌘C may not land, so check `changeCount`.
- A translation in the wrong script is a failure, not a result (Phase 2, when an LLM may answer in the wrong language).

*(SmartDock: `NSAppleScript` reported success for a change macOS had refused.)*

**Release the keys before pressing others.** The hotkey fires while its modifiers (⌃⌥⇧ by default) are still held, so a synthetic ⌘C sent at that moment arrives as ⌃⌥⇧⌘C and does nothing. Wait until the physical modifiers are released (10 ms steps, ≤ 1 s), then post with explicit flags. Explicit flags alone are not enough; Espanso and Sorla measured the same.

**Zero idle cost.** No timers, polling or event taps while idle; only Carbon hotkeys and AppKit events wake the app. A bounded wait is allowed only inside an action the user started. Anything else needs an ADR.

**Text stays private.** User text never leaves the Mac (the Phase 2 LLM is local too) and is never logged. A diagnostic that could reveal what was typed uses `privacy: .private`; the input source a fix switches to says which layout the text is in, not what it says, and is logged publicly.

**A layout is data, not code.** Each keyboard layout is one file holding two 47-character strings in ANSI key order, and language pairs are derived from them. Tests pin every layout's length, uniqueness and round trip, so a typo fails the build instead of a user's sentence.

**Break the build rather than write a note.** Where the compiler can reach, agreement between two places is enforced by an exhaustive switch (`AppCommand` → title, default hotkey, menu item, action). Where it cannot, a test or make target enforces it (Services in `Info.plist` ↔ `TextServiceProvider` selectors, and every Services title translated: `ServicesDeclarationTests`). *(SmartDock.)*

**A list repeated in two places will drift.** Commands, hotkeys, menu items and services come from one `AppCommand` list; layouts come from one provider. Drive code from `allCases` with an exhaustive switch rather than a hand-written list. *(SmartDock: a hand-written backfill drifted to five of its ten settings.)*

## Build & Run

The Makefile is the interface, mirroring SmartDock.

```bash
make build / test / app / run / clean         # swift build -c release · swift test · bundle (ad-hoc) · open · clean
make icon                                     # draw Resources/AppIcon.icns (make app redraws it when the script changes)
make format / lint / coverage                 # swift-format apply · check (CI gates) · llvm-cov table
make bump V=1.2.3 / version-check / release   # version everywhere · verify refs · build + zip + gh release
make changelog-check / release-notes          # this version's notes exist · print them
make install / fix                            # copy to /Applications + refresh Services · xattr -cr + codesign
make docs-check / footprint                   # links, anchors, file table · idle CPU, wakeups, memory of the running app
make l10n / l10n-check                        # add new UI strings to the catalog · every string used and translated
make doctor / logs / actions-check            # environment check · live log · Actions vs latest
swift test --filter <testName>                # one test
```

Builds are ad-hoc signed, for development as for releases (ADR-015), so macOS drops the Accessibility grant after every rebuild. Grant Access… restores it, from Settings ▸ General, the menu or an alert: it clears the stale entry and restarts SmartType. `make app SIGN_ID="<identity>"` signs with a stable identity of your own, never with a company's certificate.

## Version & Release

**Never edit a version by hand — always `make bump V=x.y.z`.** The version is written in four places, and `bump` is the only thing that knows all of them; `version-check` fails if any reference is stale:
- the `Makefile` (source of truth);
- `Resources/Info.plist` (`CFBundleShortVersionString`, and `CFBundleVersion` +1);
- the README badge (URL and alt text);
- a dated section in `CHANGELOG.md`.

Before the first release, `VERSION` is the version being built (`0.1.0`) and the CHANGELOG has no dated section yet. `version-check` reports that state as *unreleased* instead of failing, and the first `make bump V=0.1.0` opens the section.

**Never delete `## [Unreleased]`.** `bump` opens the new section directly under it, so whatever accumulated there becomes the release notes. `changelog-check` refuses a release whose notes are empty, and both `make release` and `release.yml` call it. *(SmartDock shipped two releases with empty notes before the check sat on both paths.)*

**Releasing is the user's step:** `make bump V=x.y.z` → fill in the notes → commit → merge `dev` into `main` → tag `vX.Y.Z` on `main` → push the tag. `release.yml` then runs:
1. 🧪 Test.
2. 🔨 Build: `make bump`, `changelog-check`, `release-notes`, `make app`, zip.
3. 🎉 GitHub Release, with the CHANGELOG section as its body.
4. 🍺 Homebrew. Over SSH with the `TAP_DEPLOY_KEY` secret, it updates `Casks/smarttype.rb` (zip + sha256) and `Formula/smarttype.rb` (source tarball + sha256) in `alexeikaratai/homebrew-tap`. It fails if a download failed (`curl -f`: without it, GitHub's "Not Found" page is saved with exit 0 and its hash would go into the tap; measured) or a `sed` matched nothing.

The workflow's own `make bump` adds one to the build number again, so a release ships one build above its commit (v0.1.0: build 3, committed 2; measured), as SmartDock's releases do.

**Set up once, in Stage 5:**
- The repository is public: Homebrew cannot download release assets of a private one, so it went public before the first tag.
- The deploy key «smarttype release» has write access to the tap, and its private half is this repository's `TAP_DEPLOY_KEY` secret. The tap's two files were written by hand; the workflow only updates them.
- The cask takes Apple silicon only (`depends_on arch: :arm64`, ADR-010), because the release is built on an arm64 runner. The formula runs `make app`, so it builds the same bundle a developer does.

## CI/CD

`ci.yml` and `dependabot.yml` came with Stage 1, `release.yml` with Stage 5.
- **`ci.yml`** (pushes to `main`/`dev`, PRs to `main`/`dev`, and manual runs):
  - Concurrency per branch, read-only permissions, SPM cache.
  - Then `version-check` → `docs-check` → `l10n-check` → `lint` → `coverage` → `swift build -c release` → `make app` + `codesign --verify --strict`.
  - Then the bundle is launched on macOS 14 and 15 runners and must stay up for 5 s: nothing else ever starts it below the dev machine's macOS 27.
  - Lint runs before the tests and the build, so a formatting PR fails in seconds.
- **`release.yml`** (a `v*` tag): as above. Only the release job's token may write; the tap is pushed with its deploy key.
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
  - `.build/release` becomes a symlink into `out/Products/Release`, modules are bundle directories, and there is one test bundle per test target, named after it. `make coverage` reads every bundle: reading the first left `SmartTypeEngines` out of the report while every test passed (measured with Stage 3a).
  - Anything that reaches into `.build` by path must handle both layouts.
  - Recipes run under `set -e`.
  - When a toolchain changes, run every make target.
- **`swift-format` in Xcode 27 requires `orderedImports.shouldGroupImports`** in `.swift-format`. Set it to `true`; the Xcode 26 formatter ignores it.
- **A workflow step creates what it writes into** (`mkdir -p build`). A developer's machine always has leftovers that a fresh runner does not.
- **Stale build after changing an initialiser used as a default argument.** The link fails with `Undefined symbols`; run `rm -rf .build && swift build`.
- **macOS 26 draws no `NSMenuItem.image` in a status menu.** If menu items need icons, put the SF Symbol as an `NSTextAttachment` in `attributedTitle` and align with a tab stop.
- **`open` can hand a launch to an app that is already gone.** For a short while after the process exits, LaunchServices still treats the app as running, so a plain `open` "activates" it and nothing starts. Measured: one launch in three failed, even after waiting for the process to exit. `make run` stops the old instance, waits for it, and then uses `open -n`.
- **A hosting view's size includes the title bar only after the window lays out.** In a `.fullSizeContentView` window SwiftUI places the content below the title bar, so the window must be taller by the bar. Sized before `window.layoutIfNeeded()`, the Settings window came out 32pt short and clipped its bottom (measured; pinned by a test).
- **Give a literal its type inside `#expect` when comparing `CGFloat`.** `#expect(frame.maxX == 1400 - 12)` failed with both sides printed as 1388, the literal arithmetic having been typed as something else; `CGFloat(1400) - gap` passed (measured).
- **`NSImage.lockFocus` draws at the screen's scale.** On a Retina Mac an icon PNG drawn that way comes out twice the size its name says. `scripts/generate-icon.swift` draws every size into an `NSBitmapImageRep` of exact pixels, checked with `sips` after `iconutil -c iconset`.
- **Rebuilding the bundle under a running SmartType breaks its Accessibility.** `tccd` checks a request against the code on disk, not the running one: after `make app` replaced the bundle, every AX query was refused (`Failed to match existing code requirement`, `authValue=0` in tccd's log), while `AXIsProcessTrusted()` inside the running app still said yes, so Translate fell back to ⌘C everywhere (measured in 4c). After a rebuild, `make run` and Grant Access before checking anything that reads through Accessibility. A Homebrew upgrade quits the app first (`uninstall quit:`), so people never hit this.
- **Git overwrites the ignored `docs/`.** Commits from before `docs/` went private (v0.1.0 and older) still track `docs/*.md`, and `git checkout` replaces ignored files without asking (`--overwrite-ignore` is its default): checking one out puts that commit's copies over the private documents, and switching back deletes them. On 2026-10-12, `git checkout main` before main had the change emptied `docs/` (measured). Commit in `docs/` first; `git -C docs restore .` then brings them back.
- **Never call `setActivationPolicy(.accessory)`.** It can drop the status item at launch. `LSUIElement` in `Info.plist` is the only switch, so run the app through `make run`, not `swift run`.

## Architecture

`docs/ARCHITECTURE.md` is the source of truth for modules, flows, patterns and ADRs. Modules are split by isolation domain:
- `SmartTypeCore`: pure logic, nonisolated.
- `SmartTypeEngines`: nonisolated async.
- `SmartTypeApp`: `@MainActor` by default.
- `SmartType`: the executable, holding only `main.swift`.

Swift Package tools 6.2, macOS 14+, Swift 6 strict concurrency, zero dependencies.

Keep this table current, as SmartDock does: one row per file, including the measured facts that file depends on. Paths are relative to `Sources/`. `make docs-check` fails when a file has no row, or a row has no file.

| File | Responsibility |
|---|---|
| `SmartTypeCore/Language/Language.swift` | A language, by its BCP 47 code (`.english`, `.russian`). |
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
| `SmartTypeCore/Detection/LanguageDetector.swift` | The detection module: a word's plausibility from the scorers. Which language a translation comes from is `SourceLanguage`'s job; the old reading by script, written for ru↔en only, went in 4c with the `Script` type it needed. `known` beats `impossible`, `impossible` beats the rest, and among the rest the highest opinion wins. |
| `SmartTypeCore/Correction/LayoutTokenizer.swift` | Words (runs of non-whitespace, punctuation attached) and whitespace, in one pass. |
| `SmartTypeCore/Correction/LayoutCorrector.swift` | A word's source is the only layout that could have typed it. One source for the whole selection: convert it whole. Mixed sources: decide word by word, and a tie keeps the word. The target is the layout of the last converted word. |
| `SmartTypeCore/Correction/Correction.swift` | The fixed text and the layout to switch to. |
| `SmartTypeCore/Translation/TranslationTarget.swift` | The language a translation goes into: the person's pick unless the text is already in it, else the first of their macOS languages the text is not in; text in all of them goes into English, English into Russian. |
| `SmartTypeEngines/TranslationEngine.swift` | One way to translate, with a name the panel shows. Throws `TranslationFailure`, and lets cancellation through. |
| `SmartTypeEngines/TranslationFailure.swift` | Why an engine did not translate: unavailable on this Mac, the pair not downloaded, the pair not supported, or failed. |
| `SmartTypeEngines/FallbackTranslator.swift` | Asks engines in order and keeps every skipped one's reason. Checks for cancellation before each engine; cancellation is rethrown, never reported as a failure. |
| `SmartTypeEngines/SourceLanguage.swift` | The source language, from `NLLanguageRecognizer`. Measured: sentences 1.00; "hello" 0.13 and "привет" read as Bulgarian at 0.53, so below 0.9 the person's languages are hints. |
| `SmartTypeEngines/Apple/AppleTranslationEngine.swift` | Apple's on-device engine, macOS 26+: `LanguageAvailability` first, then `TranslationSession(installedSource:target:)`. Measured on macOS 27: ru→en 1.0 s cold, en→ru 0.34 s; a cancelled translation runs to the end before it throws (13.8 s for ~1,800 characters). Linked weakly without a flag (`otool -l`: LC_LOAD_WEAK_DYLIB). `supportedLanguages()` is `@concurrent`: `LanguageAvailability` is not `Sendable`, and asking it from a caller-isolated function fails to compile. |
| `SmartType/main.swift` | Entry point: `NSApplication` plus a top-level `AppDelegate`. `delegate` is weak, so the top-level constant is what keeps it alive. No `setActivationPolicy`; `LSUIElement` lives in `Resources/Info.plist`. |
| `SmartTypeApp/App/AppDelegate.swift` | Builds `AppComposition` in `applicationDidFinishLaunching`. |
| `SmartTypeApp/App/AppComposition.swift` | Composition root. Logs each command with the app in front and whether Secure Input is on, never any text. Registers the shortcuts through `HotKeyBindings`, offers the Services provider (`offerToServices`, a seam: `NSApp.servicesProvider` plus `NSUpdateDynamicServices()`), and owns `perform(_:)`, the single entry point for every command: Fix Layout runs `LayoutFixAction`, Translate runs `TranslateAction`. Builds the Settings window controller and both actions on first use, so neither the window, the dictionary nor the panel loads before it is needed. Both actions share one `ClipboardTransaction`. At start, when the last run ended in a reset, it asks for Accessibility and opens Settings, as SmartDock does. `stop()` lets a test take its status item down. |
| `SmartTypeApp/App/AppCommand.swift` | The list of commands: a localized title, a default hotkey (⌃⌥⇧L and ⌃⌥⇧T) and a `storageName`, all through exhaustive switches; the storage name is frozen, so renaming a case keeps the shortcut a person set. A `nonisolated` value type. `isAvailable` asks the running macOS (Translate needs 26) and `requirement` says what is missing. |
| `SmartTypeApp/App/AppRelauncher.swift` | Quits and starts a new instance once the old one has exited (`/bin/sh` waits up to 5 s on `kill -0`, then `open -n`), as SmartDock does. The bundle path travels in an environment variable, so it cannot become shell syntax. A relaunch that cannot be scheduled keeps the app running. |
| `SmartTypeApp/App/Log.swift` | `Logger`s under `com.smarttype.app` (`general`, `hotkeys`, `permissions`). `nonisolated`, so code with any isolation can log. Every file that logs imports `OSLog` itself; `MemberImportVisibility` rejects the transitive import (measured). |
| `SmartTypeApp/StatusBar/StatusBarController.swift` | Owns the `NSStatusItem`, whose SF Symbol `character.cursor.ibeam` is pinned by a test. Refills the menu in `menuNeedsUpdate`, so nothing runs between openings; the shortcuts and the Accessibility permission are read there too, never polled. |
| `SmartTypeApp/StatusBar/StatusMenu.swift` | Builds the menu from `AppCommand.allCases`: «⚠︎ Grant Access…» first while the Accessibility permission is missing, then one item per command with its shortcut as the key equivalent (none for a command without one), the Keyboard Shortcuts submenu listing them (refused combinations marked), Settings… ⌘, and Quit ⌘Q. A command this Mac cannot run stays in the menu with no action, its tooltip saying why. |
| `SmartTypeApp/StatusBar/NSMenuItem+Handler.swift` | Closure-based menu items: a convenience init and a private `MenuAction` target, kept alive by `representedObject` because `target` is weak. Not a subclass: the SDK's `NSMenuItem` designated initializers are nonisolated, and overriding them from this main-actor module does not compile (measured). |
| `SmartTypeApp/ContextMenu/TextServiceProvider.swift` | The right-click Services, `fixLayout` and `translate`, answered with the actions' Services doors. macOS hands the text over on a pasteboard of its own; the fixed text goes back on it and macOS puts it in place with undo, while nothing written back leaves the selection alone. Translation is only started: Services answer at once. Measured: any bundle LaunchServices knows gets its Services listed after `pbs -update`, `/Applications` or not. |
| `SmartTypeApp/Actions/LayoutFixAction.swift` | Fix Layout (⌃⌥⇧L by default). The Services door, `fixInPlace(text)`, gets the text from macOS and gives the fix back: no guards, no clipboard, no permission; the keyboard switches and nothing to fix beeps. The hotkey door's guards in order: already running (swallows auto-repeat), Translate holding the clipboard (beep), Accessibility (explains, then asks macOS), SmartType frontmost (beep), Accessibility saying nothing is selected (beep, no ⌘C). Then, with the clipboard borrowed: copy, `fix(text)` (the core operation, shared with Services in Stage 4), paste, and the input source of the last converted word, switched as the text lands. Nothing selected or nothing to fix beeps and pastes nothing; a pasteboard SmartType may not read is explained. Logs how long the copy (keys up included) and the paste took, never text. |
| `SmartTypeApp/Actions/TranslateAction.swift` | Translate (⌃⌥⇧T by default). The Services door, `translateText(text)`, needs no permission and copies nothing: before macOS 26, or with blank text, it beeps. The hotkey door's guards: macOS 26 (else a beep), a copy already running, Accessibility (explains, then asks), then the panel is closed, since it would be the focused element and take the ⌘C, and SmartType frontmost beeps. The selection is read through Accessibility first (`readSelection`, a seam): an empty or blank answer means nothing is selected and beeps without ⌘C, and no answer falls through to ⌘C in a `ClipboardTransaction`, which beeps while Fix Layout holds the clipboard and gives the clipboard back after. Blank text beeps. `translate(text)` is the core operation, shared with Services; once the translation lands, the panel is fitted to it in the same step. Logs the outcome and how long it took, never text. |
| `SmartTypeApp/Panel/FloatingPanel.swift` | A borderless, clear, non-activating `NSPanel` over every Space, full-screen ones included, that becomes key without activating SmartType; a borderless window needs `canBecomeKey` for that. The card draws its own glass and corners, and the window's shadow follows it. Esc and losing key status both call `onClose`. |
| `SmartTypeApp/Panel/PanelController.swift` | One panel for the app's life, as big as its card's `fittingSize` and placed by `PanelPlacement` on the screen under the pointer. `fitToCard()` runs in the same step as the card's change: SwiftUI applies a change on its next pass, where AppKit grows the window from its bottom edge and the card jumped up (measured), while `layoutSubtreeIfNeeded()` applies it at once (measured). The card is placed again from the pointer it opened at. Clicks elsewhere are watched with a global monitor, which needs no permission, only while it is up. `present` is a seam, so no test puts a panel on the screen. |
| `SmartTypeApp/Panel/PanelPlacement.swift` | Below and to the right of the pointer, flipped left or above at the edges, and clamped to the visible area for a pointer over the menu bar or the Dock (a test point each; without them the clamp went untested). |
| `SmartTypeApp/Panel/TranslationChoices.swift` | The source and target picked in Settings ▸ Translation, in UserDefaults under `com.smarttype.translation.`; nothing picked means detect, and translate into the person's languages. |
| `SmartTypeApp/Panel/TranslationViewModel.swift` | `@Observable` card: the original, the two languages (the picks from Settings, or the detected source and `TranslationTarget`'s choice), and translating, translated or a problem. A card translates once. Refuses text over 2,000 characters before asking the engine. `isCopied` turns Copy into Copied. Copy and the System Settings link are seams. |
| `SmartTypeApp/Panel/TranslationView.swift` | The SwiftUI card: "RUSSIAN → ENGLISH" as text, the original small, the translation large and selectable, the engine, and Copy on ↩. As tall as its text: under `fixedSize` a `ScrollView` is as tall as its content, and a frame caps it at 320pt, past which the translation scrolls (measured). |
| `SmartTypeApp/Panel/ProblemView.swift` | What the card says without a translation, with a button to Translation Languages when a pair is not downloaded. |
| `SmartTypeApp/Panel/GlassStyle.swift` | `cardBackground` and `cardButtonStyle`: Liquid Glass (`glassEffect`, `.glass`) from macOS 26, the system material and bordered buttons before it. The card's material only has to compile, since translation needs macOS 26; the bordered buttons ship, in Settings ▸ Shortcuts on macOS 14 and 15. |
| `SmartTypeApp/Panel/Locale.Language+DisplayName.swift` | A language's name in the app's language, capitalized as in a list ("Английский"). `displayNameWithoutRegion` is for the card's header: the macOS language list holds "ru-PL", which would read "Russian (Poland)", and Traditional Chinese keeps "(Taiwan)" (measured). |
| `SmartTypeApp/Permissions/AccessibilityPermission.swift` | Privacy & Security ▸ Accessibility behind seams: the trust check, the system prompt (the literal key `"AXTrustedCheckOptionPrompt"`), the Privacy pane (`x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`) and `/usr/bin/tccutil reset Accessibility <bundle ID>`, run without blocking the main thread. The bundle ID is never empty: without one, `tccutil` would reset every app on the Mac. `settingName` names the permission as the running macOS does. `grantAccess()` is Grant Access, wherever it is pressed: it always clears the entry, since a stale one cannot be told from none (the TCC database is closed to apps), sets `asksAfterNextLaunch` and relaunches; when `tccutil` fails, this process asks instead. `relaunch` has no default, so only the composition root passes the real one and no test can quit the test run. |
| `SmartTypeApp/Permissions/Onboarding.swift` | The modal alerts behind both commands' refusals: Accessibility (named as the running macOS names it, with Grant Access…, which clears the entry and restarts, and a sentence saying so) and Paste from Other Apps. A seam in both actions, so no test shows one. |
| `SmartTypeApp/Settings/SettingsWindowController.swift` | Builds the window when it opens and frees it, with its view model, when it closes (pinned by a test; a real show on screen was checked once with a probe). Inside the glass, SwiftUI lets the content go on the run loop's next turn, after the window (measured: within 50 ms), so the test waits for it. From macOS 26 the whole window is Liquid Glass: clear itself, with an `NSGlassEffectView` under the content, rounded 16pt as the window is (measured on macOS 27; the window's corner mask clips the glass either way, clear or not). Glass follows light and dark, where SmartDock's HUD material stayed dark in light mode and read as white text on grey (seen live). Before 26, the standard background. The size is taken after `window.layoutIfNeeded()`, because only then does it include the title bar the SwiftUI content sits below (measured: 32pt short otherwise; pinned by a test). Reads the permission again whenever the window becomes key. A shortcut recording under way ends as the window closes, so the hotkeys come back (a test pins it; SwiftUI's `onDisappear` did not catch it). `present` is a seam, so no test puts a window on the screen. |
| `SmartTypeApp/Settings/SettingsWindow.swift` | Closes on Esc and ⌘W. An agent app has no main menu, so nothing else answers ⌘W; the key is matched by key code, because with Russian – PC active it types "ц". |
| `SmartTypeApp/Settings/SettingsView.swift` | The content, laid out as SmartDock's: icon, name, version and "Made with ❤" on top, then the segmented tabs (`SettingsTab`): General, Translation, Shortcuts, About. The first three are grouped forms, as in System Settings, on the window's own background. |
| `SmartTypeApp/Settings/GeneralView.swift` | The Accessibility status, which both commands need, and while it is missing one button, Grant Access…, with a line on what it does, in a grouped form. A failed reset shows the command to run in Terminal. |
| `SmartTypeApp/Settings/AccessibilityViewModel.swift` | `@Observable` state for General: the status, read when the window opens and on refresh, never polled. `grantAccess()` runs the permission's, and raises the failure alert when the entry could not be cleared. |
| `SmartTypeApp/Settings/TranslationSettingsView.swift` | Translate from and Translate into: Automatic, or any language Apple's engine supports. Disabled before macOS 26, with a note. The languages are asked for when the tab appears. |
| `SmartTypeApp/Settings/TranslationSettingsModel.swift` | `@Observable` picks for the Translation tab, stored through `TranslationChoices`; `nil` is Automatic. Asks Apple's engine for its languages once per window (21 on macOS 27.0.1, measured) and keeps them in their shortest form: the engine says "en-US" where a stored pick says "en", and `Locale.Language` compares identifiers (measured: "en-US" is not "en"). A pick always has a row, so a picker never shows a selection without one. |
| `SmartTypeApp/Settings/ShortcutsView.swift` | Each command's shortcut in a grouped form, from `AppCommand.allCases`: the field, why a combination was refused, and whether macOS registered it. Stops a recording when the tab goes. |
| `SmartTypeApp/Settings/ShortcutField.swift` | The shortcut as a button that records the next keys, showing the modifiers as they are held, and ↺ back to the default once it is another. |
| `SmartTypeApp/Settings/ShortcutsViewModel.swift` | `@Observable` recording: it pauses the hotkeys, or Carbon would take the keys before the window, and watches the keyboard with a local monitor (a seam), both only while recording. Esc cancels, ⌫ leaves the command without a shortcut, and a refused combination shows why while the recording goes on. |
| `SmartTypeApp/Settings/AboutView.swift` | Version and build, what SmartType does, GitHub and Changelog, "Made with ❤ by Alex Karatai". |
| `SmartTypeApp/Settings/AppInfo.swift` | The version and build from Info.plist, the repository links and the author's signature, shared by the header and About. |
| `SmartTypeApp/System/HotKeys/KeyCombo.swift` | `KeyCombo` and `Modifiers`: the display string (⌃⌥⇧L), Carbon flags and `NSEvent.ModifierFlags` both ways, all from one table. The stored form is `{keyCode, modifiers}`, frozen: a change would lose every shortcut people set; a value this version cannot use reads as nothing. Caps Lock and fn are dropped, and macOS's own shortcuts carry fn (0x20000) in 106 of the 176 switched on (measured). |
| `SmartTypeApp/System/HotKeys/Key.swift` | A physical key by its `kVK_*` code, with its label and menu key equivalent. The 47 character keys come from SmartTypeCore's U.S. layout, so the codes are listed once; Space, Return, Tab, the deletes, the arrows, Home, End, Page Up and Down and F1–F20 are named here. Esc is left out: it cancels a recording. |
| `SmartTypeApp/System/HotKeys/KeyPress.swift` | A key event as a recording needs it, `Sendable`, so the key monitor hands the main actor values instead of an `NSEvent`. |
| `SmartTypeApp/System/HotKeys/HotKeyStore.swift` | The person's shortcuts in UserDefaults, `com.smarttype.shortcut.<command>`: `{keyCode, modifiers}`, `{}` for none, and nothing for the default, so a later default reaches everyone who kept it. Frozen. |
| `SmartTypeApp/System/HotKeys/HotKeyRules.swift` | What a shortcut may be: ⌃, or ⌘ together with ⌥ (⌘ alone would take keys every app uses, and some macOS 15 builds refuse ⌥ alone); not one macOS has switched on (`CopySymbolicHotKeys`); not the other command's. Carbon registers nearly anything, ⌘C and ⌘Space included, and reports a clash only within one process (−9878; measured), so these rules are SmartType's own. |
| `SmartTypeApp/System/HotKeys/HotKeyBindings.swift` | Which combination runs which command: the store, registration through `HotKeyCenter`, the commands macOS refused, and `pause()` while Settings records. Every change registers all shortcuts afresh. |
| `SmartTypeApp/System/HotKeys/HotKeyCenter.swift` | `HotKeyRegistering` (the seam) and `HotKeyCenter`: identifiers and actions. A refused combination never keeps an action; this guard is proven by mutation. |
| `SmartTypeApp/System/HotKeys/CarbonHotKeyRegistrar.swift` | The real implementation behind the seam: `RegisterEventHotKey`, one event handler, the signature `SMTY`. The C callback is `nonisolated` and hands the identifier back through `MainActor.assumeIsolated`. `deinit` tears down through `nonisolated(unsafe)` storage. Not covered by tests; verified live. |
| `SmartTypeApp/System/Keyboard/KeystrokeSender.swift` | ⌘C and ⌘V as `CGEvent`s to `.cgSessionEventTap` with explicit flags, posted only once the physical ⌃⌥⇧⌘ are up (`CGEventSource.flagsState(.hidSystemState)` reads 0 with nothing held; measured), polling every 10 ms for at most a second. Caps Lock does not block. |
| `SmartTypeApp/System/Keyboard/InputSourceSwitcher.swift` | Selects an enabled input source by its TIS ID. For an ID that is not enabled, `TISCreateInputSourceList` answers nil rather than an empty list (measured), which reads as "not selected". |
| `SmartTypeApp/System/Selection/AXSelectionReader.swift` | The focused element's selected text through Accessibility (ADR-006): no pasteboard, no paste prompt. `nil` when the app does not say (secure fields, and Electron apps whose accessibility is off); an empty string when it says nothing is selected. Logs which app answered what, never the text: that log is how 4c learnt VS Code's empty answer is true. Sets a 0.25 s timeout on the system-wide element, which covers every call after it, so a frozen app cannot hold SmartType for AX's default 6 s. Not reachable from tests: AX answers only a trusted process, and the test runner is not one (measured: `AXIsProcessTrusted()` false, −25204); verified live. |
| `SmartTypeApp/System/Selection/PasteboardSnapshot.swift` | Every item in every type, in order, and puts them back. Fails when the pasteboard lists types but gives no data: what a refused read looks like (`declareTypes` without data reproduces it in 2 ms; measured). |
| `SmartTypeApp/System/Selection/ClipboardTransaction.swift` | Borrows the pasteboard: snapshot, ⌘C (waits for the change count and the app's types, ≤ 0.5 s), the fixed text written with the nspasteboard.org transient markers and pasted with ⌘V; `run` then waits 250 ms for the app to read it and puts the snapshot back only while the change count is still SmartType's. Not borrowed at all when Paste from Other Apps is Deny. One instance serves both commands, and `isBorrowed` tells either that the other has it. |
| `SmartTypeApp/System/Spelling/SpellCheckScorer.swift` | `NSSpellChecker` as a `WordScorer`: spelled correctly is `known`, a misspelling only `unknown`. Main-thread only, hence an isolated conformance. Measured on macOS 27: привет and написал are known in Russian, руддщ is not; hello is known in English, ghbdtn is not. |

## Code Style

`swift-format` is authoritative, with the same configuration as SmartDock: `.swift-format`, `make format` / `make lint`, reached through `xcrun swift-format`. Beyond the formatter:

- **Names.** `UpperCamelCase` for types, `lowerCamelCase` for everything else, constants included. Protocols end in `-ing`/`-able`. Bools read as assertions (`isGranted`, `isShown`, `isCopied`). Abbreviations keep Apple's casing (`layoutID`, `URL`).
- **Layout.** `// MARK: -` sections; properties → init → API → private; protocol conformances in extensions at the bottom. One primary type per file (small companion types allowed). Files ≲ 150 lines, functions under ~40.
- **Access.** `private` by default and `internal` never written out. Cross-target API is `package`, never `public`. `final` on every class.
- **Values.** `struct` and `let` unless there is a reason; a caseless `enum` for namespaces. Force unwraps only for AppKit objects set right after init. No `Any`, except where a C or AppKit API hands one over.
- **Control flow.** `guard` + early return; `[weak self]` in escaping closures, with `self?.` for one call and `guard let self` for more; default parameters over overloads; `lazy var` for expensive one-time setup.
- **Comments.** Names over comments. A comment says *why*, never *what*. Doc comments go on cross-target API.
- **Seams at the process boundary.** Every call that leaves the process goes through a parameter (protocol or closure) whose default is the real thing: CGEvent posting, the general pasteboard, TIS, AX, `NSWorkspace.open`, `AXIsProcessTrustedWithOptions`, `NSSpellChecker`, Translation, `NSAlert`. The app passes nothing; a test passes a recorder. *(SmartDock: an unseamed modal alert hangs the whole test suite.)*
- **Logging.** Through `Log`, never `print()`.

## Testing

Swift Testing (`@Suite`, `@Test`, `#expect`), with suites running in parallel.

- Logic lives in `SmartTypeCore` whenever it can, and is covered there: every layout, every conversion and correction case, every scorer rule.
- The real Apple engine translates in a test only where the pair is downloaded: its `.enabled` condition asks `LanguageAvailability`, so CI, which has no packs, skips it rather than fails. The unsupported-pair test needs no pack and runs everywhere.
- Actions are tested with recorders at the process boundary; the real system calls are verified live (step 8).
- Tests never touch the user's clipboard, input source or Accessibility state. Use a private `NSPasteboard(name:)`, an injected input-source switcher and an injected trust check.
- Acceptance tests from the spec are written before the code that makes them pass (step 5).
- A test that waits for the main queue waits for the event (a `waitUntil` helper), never for a fixed time.
- A suite that triggers menu actions creates `NSApplication.shared` in its `init`. `performActionForItem` sends the action through `NSApp`, and without it a test passed or failed depending on which suite happened to run first (measured with a mutation).
- Actions run against `FakeFrontApp` in `Mocks.swift`: the frontmost app on a private pasteboard, which copies its selection on ⌘C and records ⌘V. No test sends a real keystroke or touches the real clipboard.
- A new guard is proven by mutation (step 9).
- Fakes live in each test target's `Mocks.swift`, and helpers such as `waitUntil` in `TestSupport.swift`, created when the first helper is needed. This mirrors SmartDock.

## Conventions

**Concurrency.**
- Swift 6 language mode. `SmartTypeApp` has `defaultIsolation(MainActor)`; Core is nonisolated, with `Sendable` data types.
- No `Task.detached`.
- Carbon and Services callbacks arrive on the main thread; assert this with `MainActor.assumeIsolated`.
- The engines and the chain let cancellation through, but nothing cancels yet: a translation whose panel closed runs to its end (Apple's engine cannot be interrupted anyway) and lands in a card nobody shows.

**AppKit.** Programmatic UI, no nibs. SwiftUI only as content inside AppKit windows (`NSHostingView`, or `NSHostingController` where a view controller is wanted). `LSUIElement = true`. SF Symbols, and no SwiftPM resources (they break bundle signing).

**Hotkeys.** Carbon `RegisterEventHotKey`. The defaults are ⌃⌥⇧L and ⌃⌥⇧T, one key more than ⌃⌥ so a stray press in another app is less likely (decided 2026-10-12), and a person sets their own in Settings ▸ Shortcuts. A shortcut needs ⌃, or ⌘ together with ⌥: ⌘ alone would take keys every app uses, and some macOS 15 builds reject combinations made only of ⌥ or ⌥⇧. Carbon registers nearly anything and reports no conflict with other apps' hotkeys (measured), so `HotKeyRules` refuses the shortcuts macOS uses and the other command's; a clash with another app cannot be seen, and Settings says so. While a shortcut is recorded the hotkeys are paused, or Carbon would take the keys first.

**Accessibility & TCC.** macOS 27 renamed the Privacy & Security row: Accessibility is now Device Control and Data Access («Управление устройством и доступ к данным»), measured in System Settings' own string tables. The API, the TCC service (`tccutil reset Accessibility`) and the `Privacy_Accessibility` deep link did not change, so only text does: the UI names the row as the running macOS does (`AccessibilityPermission.settingName`), and code and docs keep saying Accessibility. After `tccutil reset`, a request from the same running process is only checked (tccd: `authValue=1`, `authReason=5`) and SmartType does not reappear in the list, so a reset ends in a relaunch (measured). Ad-hoc signing changes the code hash on every build, and macOS silently drops the grant. Re-grant it with Grant Access…, which clears the entry and restarts, or run `tccutil reset Accessibility com.smarttype.app`. `tccutil` finds the app through LaunchServices: with no bundle registered under the ID it fails with −10814 (measured in Stage 5, between removing one build and installing the next), while Grant Access runs it from the running app, whose bundle is registered. On macOS 27 that command needs no administrator password, with or without an entry: measured from the app on a stale grant after a rebuild (exit 0; a command-line tool cannot ask for a password, so it would have failed instead). The prompt key is the literal `"AXTrustedCheckOptionPrompt"`: the C constant is imported as a `var`, which Swift 6 rejects.

**Pasteboard.** Since macOS 15.4, reading the general pasteboard's contents asks the person, while `changeCount`, `types` and the detection calls do not (SDK headers). The setting lives in Privacy & Security ▸ Paste from Other Apps («Вставка из других приложений»), and macOS warns that a change may need the app relaunched (both measured in System Settings' own strings). Never read contents to find out whether something changed: compare `changeCount`, then check `types`.

**Localization.**
- The interface is English with a Russian translation, and follows the language of macOS. A person can pick a language per app in System Settings → General → Language & Region → Applications.
- Every UI string is `String(localized: "English text", comment: "where it appears")`. The English text is the key; keys are plain literals. Compose with code (a title plus a shortcut) rather than interpolating inside a key.
- In SwiftUI, pass that string: `Text(String(localized: …))`. A bare `Text("…")` localizes through `LocalizedStringKey`, which `make l10n-check` cannot see, so the check refuses it. A name that is never translated uses `Text(verbatim:)`.
- Translations live in `Resources/Localizable.xcstrings`. `make l10n` adds new keys (Apple's `xcstringstool extract` + `sync`); then translate them into Russian.
- `make l10n-check` fails on a key that is not a plain literal, a key missing from the catalog, a stale key or a missing Russian value. `make app` runs it before bundling and compiles the catalog into `ru.lproj`.
- The check reads the sources itself instead of calling `xcstringstool extract`. Measured on Xcode 27; whether Xcode 26.6 on CI has `extract` was not confirmed, so the check depends on nothing beyond Swift.
- The bundle has no `en.lproj` and needs none. The English strings are the keys, and `CFBundleLocalizations [en, ru]` with development region `en` make English selectable. Measured with `Bundle.preferredLocalizations`: `en-US` first resolves to English, `ru` first to Russian, `de-DE` falls back to English.
- Tests run without the app bundle, so they see the English keys.
- Services titles live in `Resources/ServicesMenu.xcstrings`, keyed by the `NSMenuItem` default in `Info.plist`; `make app` compiles them into `ru.lproj/ServicesMenu.strings`, where macOS looks for them, and a test refuses a title without Russian.

**Identifiers.** The bundle ID and log subsystem are both `com.smarttype.app`. UserDefaults keys live under `com.smarttype.`.

**Logging.** `Log` (three `Logger`s under `com.smarttype.app`). Record at **notice** or above, since `.info` and `.debug` are not persisted and are invisible to `log show`.

## Entitlements & Permissions

- **Sandbox:** off, because the app sends synthetic input and Services into other apps.
- **Signing:** ad-hoc builds carry no entitlements file. Hardened runtime comes only with a Developer ID (`make sign`, later).
- **Accessibility:** needed to post ⌘C/⌘V and to read the selection through AX.
- **Pasteboard access (macOS 15.4+):** Fix Layout's hotkey reads the general pasteboard, and Translate's only when the app says nothing through Accessibility; Services and AX reading do not.
- **Apple engine:** translation languages must be installed (System Settings → General → Language & Region → Translation Languages).
