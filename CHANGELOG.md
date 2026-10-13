# Changelog

All notable changes to SmartType are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- The translation panel's Copy button is just its icon, which turns into a checkmark once the
  translation is copied. ↩ still copies, and VoiceOver and the tooltip still say Copy.

## [0.2.0] — 2026-10-13

### Added

- **Open at Login.** Settings ▸ General has a switch that starts SmartType when you log in, so
  its shortcuts work right after a restart. It stays off until you turn it on. If you turned
  SmartType off in System Settings' Login Items, the switch says so, with a button that opens
  them.

## [0.1.0] — 2026-10-12

### Added

- **Install with Homebrew:** `brew install --cask alexeikaratai/tap/smarttype` on a Mac with
  Apple silicon and macOS 14 or later, or `brew install --formula alexeikaratai/tap/smarttype`
  to build it from source with Xcode 26. SmartType is ad-hoc signed, so macOS drops its
  Accessibility permission with each update, and «Grant Access…» in the menu gives it back.
- SmartType is free and open source, under the MIT license.
- **Both commands are in the right-click Services menu**: select text in a Mac app, then
  Services ▸ «SmartType: Fix Layout» or «SmartType: Translate». From there the fix replaces
  the text in place, with the app's own undo, and switches the keyboard; nothing goes
  through your clipboard and no permission is needed. Translate opens the panel. You can
  give either one a shortcut of your own in System Settings ▸ Keyboard ▸ Keyboard
  Shortcuts ▸ Services.
- **⌃⌥⇧T translates the selected text** in a panel next to the pointer, on the Mac itself:
  Apple's on-device translation, macOS 26 and later. The language of the text is
  recognized, and it goes into the first of your macOS languages it is not already in; to
  translate from a language of your choice, or into one (unless the text is already in it),
  pick it in Settings ▸ Translation. The panel is a Liquid Glass card that says which way it
  translates, keeps the original small above the translation, and grows to fit it, from the
  edge next to the pointer. Select the translation, or copy it with ↩. Esc or a click
  elsewhere closes the panel. Where the app tells it through Accessibility, the selection is
  read without touching your clipboard, and macOS asks nothing about pasting; other apps get
  ⌘C, and your clipboard is given back as soon as the selection is read. With nothing
  selected it beeps, and where the app says so through Accessibility, it does not even copy.
  Copy puts the translation on the clipboard. A pair of languages not downloaded yet comes
  with a button to the place in System Settings that downloads it. On older macOS, Translate
  is greyed out in the menu and says why.
- SmartType has its own icon: one key with two legends, F and А, since the same key types
  either one depending on the layout, which is the very mix-up SmartType fixes. It shows in
  System Settings' permission lists, which had a blank square for it, and in Settings.
- **⌃⌥⇧L fixes the selected text.** Typed `ghbdtn` with the wrong layout on? Select it, press
  ⌃⌥⇧L, and it becomes `привет` in any app, the keyboard switching to the layout the text is
  now in. A whole selection typed in one layout is converted whole, punctuation included;
  mixed text is decided word by word, with the macOS dictionary as the judge, so
  «Привет, ghbdtn» becomes «Привет, привет». SmartType borrows the clipboard for the copy
  and the paste and puts your own content back, unless you copied something in the
  meantime; the other command, pressed meanwhile, beeps instead of taking the clipboard
  over, and clipboard managers are told to skip what SmartType writes. With nothing selected or
  nothing to fix it beeps and changes nothing. Where the app says through Accessibility that
  nothing is selected, SmartType does not even copy: the app does not beep a second time, and
  VS Code, which copies the whole line when nothing is selected, keeps that line as it is.
  Without the permission it needs, it says so and offers to grant it, and the menu shows
  «⚠︎ Grant Access…» until it is granted.
- **Settings…** (⌘,) in the menu opens a Settings window laid out as SmartDock's. General
  shows whether SmartType may use Accessibility (Device Control and Data Access, as
  macOS 27 calls it), which both commands need to copy the selected text (and the layout
  fix to paste it back), with one button, **Grant Access…**, while it is missing. It
  restarts SmartType and opens the list in System Settings, ready to be switched on; after
  an update macOS can keep SmartType switched on there while the permission no longer
  works, and the button clears that on the way. The menu's and the alerts' Grant Access do
  the same, and Settings opens next to the list to show the status, as in SmartDock.
  Translation picks the languages Translate works from and into, Automatic until you choose
  one. Shortcuts shows and changes each command's shortcut and says whether macOS accepted
  it; About shows the version, links to GitHub and the release notes, and
  "Made with ❤ by Alex Karatai". The window is built when it opens and freed when it
  closes, and SmartType still does no work while idle. Esc and ⌘W close it in any
  keyboard layout. On macOS 26 and later the window is Liquid Glass, as the translation
  card is; it follows the light or dark appearance of macOS, and its tabs are grouped as
  in System Settings.
- `make l10n-check` also refuses a bare SwiftUI `Text("…")`: its translation would come
  from a key the check cannot see, so a Russian window could show an English line.
- **Shortcuts can be changed.** In Settings ▸ Shortcuts, click a command's shortcut and
  press the new keys; Esc cancels, ⌫ leaves the command without one, and ↺ brings the
  default back. A combination macOS itself uses, the other command's, or one without ⌃ (or
  ⌘ together with ⌥) is refused with the reason, since ⌘ alone would take keys every app
  uses. The menu shows your shortcuts, and they come back after a restart. The defaults are
  ⌃⌥⇧L and ⌃⌥⇧T.
- SmartType runs in the menu bar, with no Dock icon. Its shortcuts are registered
  system-wide and fire in any keyboard layout, because they are bound to physical keys,
  not letters. The menu lists both commands with their shortcuts, and Keyboard Shortcuts
  shows whether macOS accepted each one. While idle the app uses 0.0% CPU and never wakes
  up; it takes about 16 MB of memory at launch and 29–42 MB after Settings and
  translations.
- The interface speaks English and Russian and follows the language of macOS; another
  language can be chosen per app in System Settings → General → Language & Region. The
  build refuses to make the app while any string lacks a Russian translation, so a
  Russian menu never shows a stray English word.
- Building, testing, formatting, coverage and versioning all go through `make`, the same
  way as in SmartDock, and CI runs the same checks on every push to `main` and `dev` and
  on pull requests into them.
- `make docs-check` fails the build when a link or anchor in the documentation no longer
  resolves, or when CLAUDE.md's file table no longer matches `Sources/`. Docs that drift
  from the code now stop CI instead of misleading the next reader. `make footprint` reports
  the running app's idle CPU, wakeups and memory, so "zero idle cost" is a measurement and
  not a claim.
- The design, before any code: a business plan, an architecture and a delivery plan in
  `docs/`, project instructions in `CLAUDE.md`, a contribution guide and GitHub issue and
  pull request templates. They fix what SmartType is for, how it is built and in what
  order, so the first code lands into decisions already made instead of making them.
