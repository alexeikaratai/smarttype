# CLAUDE.md

Project instructions for Claude Code. Follow these exactly.

SmartType is a macOS menu-bar assistant. ⌃⌥L fixes text typed in the wrong keyboard layout; ⌃⌥T translates the selection in a floating panel; both commands are also macOS Services in the right-click menu.

The design lives in `docs/`: [business](docs/BUSINESS.md), [architecture](docs/ARCHITECTURE.md), [delivery](docs/DELIVERY.md). This file is *how* the work is done; the architecture is *what* is built. When the two disagree, reconcile them before writing code.

The conventions mirror SmartDock (`~/work/smartdock`), the author's other menu-bar app: the same process, the same Makefile-driven release and the same Homebrew tap. A lesson carried over from there is marked *(SmartDock)*.

## Working on a Task

One task at a time, carried through these steps in order. A step is not done because it was started; each has a visible output. The tree ends up ready for the **user** to commit and release; see the last step.

### 1. Understand the task

Restate it: what changes for a person, what is in scope, and what is explicitly not. If two readings would lead to different work, ask now. Check which stage of [DELIVERY.md](docs/DELIVERY.md) the task belongs to. Work from a later stage waits for the user's go-ahead.

### 2. Measure before planning

Everything load-bearing is checked against the running system before it reaches a plan; a plan built on an assumption is worth nothing. Facts in this project that were measured, not recalled:
- The macOS 27 SDK says the general pasteboard *asks* the user on programmatic reads (`NSPasteboard.h`, `NSPasteboardAccessBehavior`).
- `TranslationSession(installedSource:target:)` exists from macOS 26, and the session type is not `Sendable` (Translation's `.swiftinterface`).
- The user's enabled keyboard layouts are `com.apple.keylayout.US` (`en`) and `com.apple.keylayout.RussianWin` (`ru`), read from the TIS input-source list.

State plainly which claims are measured and which are knowledge. "I believe" and "I checked" are different words; never let one stand in for the other.

### 3. Plan

What the change is, which files it touches, what could break, and what stays out of scope. Where there is a real choice, give options with a recommendation, not a survey.

### 4. Challenge the plan, then get a decision

Before writing code, attack the plan:
- What did it assume?
- Which call sites does it not mention?
- What would a user see that they did not ask for?

Revise it. Then wait for a decision on anything that changes behaviour users rely on or departs from [ARCHITECTURE.md](docs/ARCHITECTURE.md). A departure is recorded there as an ADR.

### 5. Implement — to the plan

Match the surrounding code. Prefer a structural fix over a patch; see **A list repeated in two places will drift** under Principles. Note every deviation from the plan as it happens; don't reconstruct it afterwards.

### 6. Reconcile with the plan

Read the plan against the diff and answer three questions explicitly:
- Planned and done.
- Planned and **not** done, and why.
- Done and **not** planned, and why.

The third group is where unreviewed behaviour hides.

### 7. Regressions and compatibility

Green tests are the floor, not the ceiling. Read every call site the change touches and ask what silently behaves differently now. Check compatibility on three axes:
- **Stored data:** UserDefaults written by earlier versions.
- **Toolchains:** CI runs Xcode 26.x, the dev machine Xcode 27 (see Gotchas).
- **Frozen contracts:** Services `NSMessage` names and menu titles, because users bind shortcuts to them in System Settings, and the `KeyCombo` storage format.

Where tests cannot reach, verify live: `make run`, read the unified log with `/usr/bin/log` (zsh shadows the name), and exercise the feature in TextEdit. Then put the machine back: quit the test build, and restore the clipboard and the input source you changed.

### 8. Tests

In this order:
1. The suite passes.
2. Anything broken is fixed, not skipped.
3. New logic in `SmartTypeCore` gets tests.
4. A new guard is proven by **mutation**: break it, watch the intended test fail, restore, re-run. A fixture that leaves a field at its default cannot catch that field being dropped.

The `SmartType` executable (`main.swift` only) is outside the test bundle. Say so rather than implying coverage, and verify it by running.

### 9. Final consistency pass

Nothing ships while any two of these disagree: the code, this file, `docs/`, `CHANGELOG.md`, `README.md`, the diff's comments.
- Every make target runs — all of them *(SmartDock: `make coverage` broke on a new Xcode while `swift test` passed)*.
- No document still describes the old behaviour, and every symbol a document names exists.
- The CHANGELOG entry sits under `## [Unreleased]` and says what changed for a person and why.

### 10. Stop at the commit

**Claude does not commit, push, tag or release.** Leave the working tree ready and say what is in it, file by file, with a suggested commit subject. Never add a `Co-Authored-By` trailer. Bumping, committing, tagging and releasing are the user's, one task per version, so a release traces to a single change.

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

The Makefile lands in Stage 1 of [DELIVERY.md](docs/DELIVERY.md); the release targets (`changelog-check`, `release-notes`, `release`) join it in Stage 5. It is the interface, mirroring SmartDock:

```bash
make build / test / app / run / clean         # swift build -c release · swift test · bundle (ad-hoc) · open · clean
make format / lint / coverage                 # swift-format apply · check (CI gates) · llvm-cov table
make bump V=1.2.3 / version-check / release   # version everywhere · verify refs · build + zip + gh release
make changelog-check / release-notes          # this version's notes exist · print them (the release body)
make install / fix                            # copy to /Applications + refresh Services · xattr -cr + codesign
make doctor / logs / actions-check            # environment check · live log · Actions vs latest
swift test --filter <testName>                # one test
```

`make app SIGN_ID="<identity>"` signs with a stable identity, so the Accessibility grant survives rebuilds while developing. Releases are ad-hoc signed, like SmartDock's.

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
- **`ci.yml`** (push to `main`/`dev`, PRs to `main`):
  - Concurrency per branch, read-only permissions, SPM cache.
  - Then `version-check` → `lint` → `coverage` → `swift build -c release` → `make app` + `codesign --verify --strict`.
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
- **Never call `setActivationPolicy(.accessory)`.** It can drop the status item at launch. `LSUIElement` in `Info.plist` is the only switch, so run the app through `make run`, not `swift run`.

## Architecture

[ARCHITECTURE.md](docs/ARCHITECTURE.md) is the source of truth for modules, flows, patterns and ADRs. Modules are split by isolation domain:
- `SmartTypeCore`: pure logic, nonisolated.
- `SmartTypeEngines`: nonisolated async.
- `SmartTypeApp`: `@MainActor` by default.
- `SmartType`: the executable, holding only `main.swift`.

Swift Package tools 6.2, macOS 14+, Swift 6 strict concurrency, zero dependencies.

As files land, keep a file → responsibility table here, as SmartDock does: one row per file, including the measured facts that file depends on.

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
- Actions are tested with recorders at the process boundary; the real system calls are verified live (step 7).
- Tests never touch the user's clipboard, input source or Accessibility state. Use a private `NSPasteboard(name:)`, an injected input-source switcher and an injected trust check.
- A test that waits for the main queue waits for the event (`waitUntil`), never for a fixed time.
- A new guard is proven by mutation (step 8).
- Each test target has its own `Mocks.swift` and `TestSupport.swift`, as in SmartDock.

## Conventions

**Concurrency.**
- Swift 6 language mode. `SmartTypeApp` has `defaultIsolation(MainActor)`; Core is nonisolated, with `Sendable` data types.
- No `Task.detached`.
- Carbon and Services callbacks arrive on the main thread; assert this with `MainActor.assumeIsolated`.
- Cancellation flows from the UI down to the engines.

**AppKit.** Programmatic UI, no nibs. SwiftUI only as content inside AppKit windows (`NSHostingController`). `LSUIElement = true`. SF Symbols, and no SwiftPM resources (they break bundle signing).

**Hotkeys.** Carbon `RegisterEventHotKey`, with ⌃⌥ defaults. Require ⌃ or ⌘ in a combination, because some macOS 15 builds reject combinations made only of ⌥ or ⌥⇧. Carbon reports no conflict with other apps' hotkeys.

**Accessibility & TCC.** Ad-hoc signing changes the code hash on every build, and macOS silently drops the grant. Re-grant it, or run `tccutil reset Accessibility com.smarttype.app`. The prompt key is the literal `"AXTrustedCheckOptionPrompt"`: the C constant is imported as a `var`, which Swift 6 rejects.

**Identifiers.** The bundle ID and log subsystem are both `com.smarttype.app`. UserDefaults keys live under `com.smarttype.`.

**Logging.** `Log` (a `Logger` with subsystem `com.smarttype.app`). Record at **notice** or above, since `.info` and `.debug` are not persisted and are invisible to `log show`.

## Entitlements & Permissions

- **Sandbox:** off, because the app sends synthetic input and Services into other apps.
- **Signing:** ad-hoc builds carry no entitlements file. Hardened runtime comes only with a Developer ID (`make sign`, later).
- **Accessibility:** needed to post ⌘C/⌘V and to read the selection through AX.
- **Pasteboard access (macOS 15.4+):** the hotkey layout fix reads the general pasteboard; Services and AX reading do not.
- **Apple engine:** translation languages must be installed (System Settings → General → Language & Region → Translation Languages).
