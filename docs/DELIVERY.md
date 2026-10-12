# SmartType — Delivery Plan

**Status:** each stage starts on the user's go-ahead. Progress is recorded in `CHANGELOG.md` (`## [Unreleased]`) and in the git history.
**Companion docs:** [Business plan](BUSINESS.md) · [Architecture](ARCHITECTURE.md) · [CLAUDE.md](../CLAUDE.md) · [CONTRIBUTING.md](../CONTRIBUTING.md)

## Principles
- **Every stage ends in a working state.** The app runs, the build is clean with warnings as errors, the tests pass, `CHANGELOG.md` has an entry under `## [Unreleased]`, and the user commits.
- **Targets are added in the stage that gives them content.** There are never empty placeholder targets.
- **AI integrations stay out of the MVP.** Local LLM translation and the LLM judge belong to Phase 2; the architecture reserves their extension points.
- **Branches.** `dev` for work, `main` for releases, as in SmartDock. Commit subjects are in the imperative mood.
- **One process, one toolchain.** The process is in [CLAUDE.md](../CLAUDE.md), and the Makefile is the interface for build, checks and release, mirroring SmartDock.

## Stages
| Step | Scope | Suggested commits | Verification |
|---|---|---|---|
| **0 — Docs & conventions** | `docs/` (business, architecture, delivery); `CLAUDE.md`; `CONTRIBUTING.md`; `CHANGELOG.md`; `README.md`; `.github/` issue and PR templates; `.gitignore` | `Add design docs and project conventions` | the documents are reviewed in the repository |
| **1 — Skeleton & toolchain** | `Package.swift` (`SmartTypeApp` + `SmartType`); `Makefile` (build, test, app, run, install, fix, clean, format, lint, coverage, bump, version-check, docs-check, footprint, doctor, logs, actions-check, help); `Resources/Info.plist`; the README version badge (`VERSION := 0.1.0`, the version being built); `.swift-format`; `ci.yml` + `dependabot.yml`; `.vscode/launch.json`; status menu in English and Russian (String Catalog, `make l10n` / `l10n-check`); Carbon hot keys | `Add SwiftPM package, Makefile and CI`; `Add menu bar app with global hotkeys in English and Russian` (as committed) | `make doctor` / `lint` / `test` / `app` all pass. No Dock icon; hotkeys are logged in both layouts while another app is in front; 0.0% idle CPU. CI is green on `dev` |
| **2 — Layout fix** | in four steps: **2a** `SmartTypeCore` + tests (layouts, converter, detection, corrector); **2b** the Settings window, moved here from Stage 4 so the permission tools exist before the steps that need the permission (builds are ad-hoc, so macOS drops the grant on every rebuild): «Settings…» ⌘, in the menu; General with the Accessibility status, «Grant Access…» and «Reset Permission…»; Shortcuts, read-only; About with "Made with ❤ by Alex Karatai", as in SmartDock; **2c** clipboard transaction, keystrokes, input sources, spelling scorer; **2d** ⌃⌥L end to end, with the Accessibility onboarding alert and «Grant Access…» in the menu while the permission is missing, and the app icon (`scripts/generate-icon.swift`, moved here from Stage 4: System Settings showed a blank square in the permission list). 2c and 2d were built and checked as one step, so the first live check of 2c was ⌃⌥L itself. 2a was committed alone; 2b–2d went in together, because 2b was not yet committed when 2c began | `Add keyboard layouts, converter and language detection`; `Add Settings window and fix the selected text's layout with ⌃⌥L`; then `Switch the layout as the fix lands and open Settings after a reset` (as committed) | Unit tests: `yfgbcfk`→`написал`, `Ghbdtn? rfr ltkf&`→`Привет, как дела?`, `@$^&,`→`";:?б`, `` ` ``→`ё`. TextEdit E2E: the text is fixed, the clipboard restored, the layout switched to Russian – PC. Watch for macOS 27 pasteboard prompts |
| **3 — Translation** | in two steps: **3a** `SmartTypeEngines` + tests (`TranslationEngine`, the chain, the Apple on-device engine, source-language recognition) and the target-language rule in Core; **3b** the floating panel with the SwiftUI card in Liquid Glass, the language picks in Settings ▸ Translation, Settings as a Liquid Glass window with grouped tabs, and ⌃⌥T. Decided 2026-10-12: Apple's engine, macOS 14 kept (translation from 26), any language into the person's pick | `Add translation engine and Apple on-device engine`; `Add translation panel with ⌃⌥T` (as committed) | Panel size, Esc, click outside, focus return, full-screen Spaces. A real ru↔en translation when the languages are installed |
| **3c — Editable shortcuts** | pulled forward from Phase 3 on the user's request (2026-10-12). Defaults ⌃⌥⇧L and ⌃⌥⇧T, one key more than ⌃⌥. Settings ▸ Shortcuts records a new combination (Esc cancels, ⌫ clears, ↺ back to the default) with the hotkeys paused meanwhile, refuses one macOS uses, the other command's, or one without ⌃ (or ⌘ with ⌥), and the menu follows. The stored form, `com.smarttype.shortcut.<command>` = `{keyCode, modifiers}`, is frozen from here | `Make shortcuts editable in Settings` (as committed) | Record ⌃⌥K for Fix Layout: it works in TextEdit at once and after a relaunch, and ⌃⌥⇧L no longer does; ⌘C and ⌃Space are refused with the reason; Esc leaves the shortcut as it was; recording with Russian – PC active shows L; the menu shows the new keys |
| **4 — Context menu & polish** | in three steps: **4a** macOS Services (fix layout, translate), with their menu titles localized through `ServicesMenu.strings`; **4b** AX-first selection readers; **4c** guards: an empty selection that Accessibility reports beeps without ⌘C, and Secure Input gets none of its own (both decided on the log of a measured round); error states; memory after use measured (framework caches, nothing cheap gives it back; see Footprint below); the unused `LanguageDetector.dominantLanguage` removed, with the `Script` type only it used; docs refresh | `Add context-menu commands via macOS Services`; `Read the selection through Accessibility first`; `Guard empty selections and drop dead detection code` | In TextEdit, right-click → Services → the layout fix replaces the text, ⌘Z undoes it, and the clipboard is untouched; translate opens the panel. Both commands in TextEdit, Notes, Mail, Safari, VS Code and Telegram, the MVP's apps (BUSINESS §6). `leaks` is clean after a series of actions; idle numbers from `footprint` / `top`; Translation.framework is weak-linked |
| **5 — First release (v0.1.0)** | `release.yml`, whose downloads fail loudly (`curl -f`); `make changelog-check` / `release-notes` / `release`; `make app` refuses a strongly linked Translation.framework, and CI launches the bundle on macOS 14 and 15; the cask, for Apple silicon only (decided 2026-10-12), and the formula, which runs `make app`, in `alexeikaratai/homebrew-tap`; the deploy key and `TAP_DEPLOY_KEY`; LICENSE, MIT (decided 2026-10-12); ADR-015 reworded without the dev machine's certificates; then `dev` merged into `main`, which still holds only Stage 0, and the repository made public | `Add release pipeline and Homebrew distribution`; then `make bump V=0.1.0` and the tag | Tag `v0.1.0` → the workflow is green, the GitHub Release body is the CHANGELOG section, and the tap is updated. `brew install --cask alexeikaratai/tap/smarttype` installs and launches on this account with SmartType's settings and permission cleared (decided 2026-10-12, instead of a new account); both commands work in TextEdit, Safari, Notes, Telegram and VS Code (carried over from 4c); `brew install --formula` builds and launches |

## Release and distribution

Since Stage 5 (v0.1.0), the same pipeline as SmartDock: one tag produces the GitHub Release and the Homebrew update.

```
 user:  make bump V=x.y.z ─► notes under [x.y.z] ─► commit ─► tag vx.y.z ─► push the tag
                                                                              │
 release.yml (on v* tag) ◄────────────────────────────────────────────────────┘
   🧪 Test      swift test
   🔨 Build     make bump · make changelog-check · make release-notes · make app · zip
   🎉 Release   SmartType-x.y.z.zip, body = this version's CHANGELOG section
   🍺 Homebrew  alexeikaratai/homebrew-tap, over SSH with TAP_DEPLOY_KEY
                  Casks/smarttype.rb     version + sha256 of the release zip
                  Formula/smarttype.rb   url + sha256 of the source tarball
                fails if any sed matched nothing — a silent no-op once broke SmartDock's formula
                fails if a download failed — curl without -f saves GitHub's "Not Found" (measured)

 users: brew install --cask alexeikaratai/tap/smarttype      brew upgrade --cask smarttype
```

- **Versioning.** `make bump V=x.y.z` is the only way to change the version. It writes the `Makefile`, `Resources/Info.plist` (short version, and build +1), the README badge and a dated `CHANGELOG.md` section, and finishes with `make version-check`.
- **Release notes.** They are whatever accumulated under `## [Unreleased]`. `make changelog-check` refuses an empty section on both paths (`make release` and `release.yml`).
- **Signing.** Releases are ad-hoc signed. The cask's postflight removes only the quarantine flag (`xattr -dr com.apple.quarantine`), as SmartDock's cask does, so the app opens without a Gatekeeper prompt; `-cr` would clear every extended attribute, ones Homebrew and Finder rely on included. Its caveat reminds the user to grant Accessibility again after an update. Developer ID signing and notarization (`make sign`) come later, once there is a certificate.
- **Cask details.** `depends_on arch: :arm64`, since the release is built on Apple silicon (ADR-010), and `macos: :sonoma`; `uninstall quit: "com.smarttype.app"`; `zap` removes `~/Library/Preferences/com.smarttype.app.plist`, the only file SmartType leaves (measured).
- **Formula.** Builds the tag's source with `make app SWIFT_BUILD_FLAGS=--disable-sandbox`, the developer's own recipe, so its bundle cannot drift from it; it needs Xcode 26.

**Set up once for the first release** (Stage 5):
1. **The LICENSE:** MIT, decided on 2026-10-12 ([business plan §7](BUSINESS.md#7-business-model-and-distribution)).
2. **A deploy key,** «smarttype release», with write access to `alexeikaratai/homebrew-tap`; its private half is this repository's secret `TAP_DEPLOY_KEY`. Created with `gh`, and the key file deleted once uploaded.
3. **The tap files,** `Casks/smarttype.rb` and `Formula/smarttype.rb`, modelled on SmartDock's. The workflow only updates them.
4. **The repository made public** by the user, right before the first tag: Homebrew cannot download release assets from a private repository.

## Verification approach
- **Every code stage** closes against the Definition of Done in [CLAUDE.md](../CLAUDE.md#definition-of-done-a-stage):
  - a clean build with warnings as errors;
  - `make lint`, `make docs-check`, `make test` (new guards proven by mutation), `make coverage`, `make app`;
  - `codesign --verify --strict` and `plutil -lint`, both run by `make app`.
- **End to end.** AppleScript drives TextEdit when the process sending the keystrokes has Accessibility. When it does not (the usual case for Claude), Claude writes a numbered manual checklist with expected results, the user runs it, and Claude confirms what it can from the log.
- **Footprint:** `make footprint` measures idle CPU, wakeups and memory. Stage 1 measured 0.0% CPU, 0 wakeups in 10 s and 17 MB; Stage 2 the same CPU and wakeups, 17 MB until Settings is first opened and 33–34 MB with it open; Stage 3c the same CPU and wakeups, 16 MB at launch and 29–42 MB after Settings and translations, over the 40 MB budget at the top end: framework caches, which `malloc_zone_pressure_relief` does not give back (measured in 4c). `leaks` after a session found 19 KB, all in three of macOS's own XPC connections (`LNDaemonApplicationInterface`), none in SmartType's code; the numbers are re-checked whenever a stage changes what runs, against the budget in [Architecture §1](ARCHITECTURE.md#1-goals-and-quality-attributes).
- **CI ≠ the dev machine.** CI builds with Xcode 26.x, the dev machine with Xcode 27. A stage is done only when CI is green as well.
- **Older macOS.** Nothing else runs SmartType below macOS 27, so CI launches the bundle on macOS 14 and 15 runners, where it must stay up for 5 s.

## After the MVP
| Phase | Scope |
|---|---|
| **Phase 2 — AI** | an Ollama engine and HTTP transport in front of the Apple engine in the fallback chain; a translation cancelled when its panel closes, which an HTTP engine can honour (Apple's runs on regardless, measured); an LLM judge for ambiguous words |
| **Phase 3 — Auto mode** | Punto-style fixing while typing (`CGEventTap`); the user's installed layouts via `UCKeyTranslate` |
| **v1.0** | launch at login, update detection after `brew upgrade`, Developer ID + notarization, polished onboarding, website; a universal binary, if Intel Macs are asked for (ADR-010) |

Details: the [business roadmap](BUSINESS.md#6-product-scope-and-roadmap) and the [extension points in the architecture](ARCHITECTURE.md#7-extension-points-including-future-ai).
