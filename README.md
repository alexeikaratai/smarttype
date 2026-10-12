<h1 align="center">SmartType</h1>

<p align="center">
  <strong>Fix text typed in the wrong keyboard layout and translate any selection — right where you type on your Mac</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-0.1.0-blue?style=flat-square" alt="Version 0.1.0"/>
  <img src="https://img.shields.io/badge/macOS-14.0%2B-000000?style=flat-square&logo=apple&logoColor=white" alt="macOS 14+"/>
  <img src="https://img.shields.io/badge/Swift-6.2-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 6.2"/>
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License: MIT"/>
</p>

---

SmartType lives in your menu bar and works in any app. Typed `ghbdtn` because the wrong layout was on? Select it, press **⌃⌥⇧L**, and it becomes `привет`; the keyboard also switches to the right layout. Need to understand or check a phrase in another language? Select it, press **⌃⌥⇧T**, and the translation appears next to the cursor. Both shortcuts can be changed in Settings, and both commands are also in the right-click **Services** menu.

Everything runs on your Mac. There are no servers and no accounts, and while idle SmartType does no work at all.

## ✨ Features

| | Feature | Details |
|---|---|---|
| ⌨️ | **Layout fix** | ⌃⌥⇧L converts the selection between U.S. QWERTY and Russian – PC (ЙЦУКЕН), Shift symbols and `ё` included, then switches the active layout |
| 🌐 | **Translation panel** | ⌃⌥⇧T shows the translation in a Liquid Glass card at the cursor: which way it translates, the original small, the translation large, Copy, Esc to close. Languages are recognized, or picked in Settings |
| 🖱️ | **Right-click Services** | Both commands in the context menu of Mac apps such as TextEdit, Notes, Mail and Safari. From there the layout fix replaces the text natively, with no clipboard and native undo. Electron apps (VS Code, Slack) build their own menus without Services; the shortcuts work there |
| 🔒 | **On-device** | Apple's on-device translation; a local LLM comes later. Your text never leaves the Mac |
| 📋 | **Clipboard-safe** | Whenever SmartType borrows the clipboard, it puts your content back |
| ⚡ | **Zero idle cost** | Event-driven: no timers, no polling, 0% CPU while idle |
| ⚙️ | **Settings** | The Accessibility status, with Grant Access while it is missing (SmartType restarts and opens the list to switch it on), the translation languages, the shortcuts (click one and press new keys), and About, laid out as SmartDock's, in Liquid Glass on macOS 26+ |
| 🌍 | **English and Russian** | The interface follows the language of macOS; pick another one per app in System Settings → General → Language & Region |
| 🧩 | **Built to grow** | A new keyboard layout is one data file; translation engines plug in behind one protocol |

## 📦 Installation

SmartType runs on a Mac with Apple silicon and macOS 14 or later; translation needs macOS 26.

### From Homebrew

```bash
brew install --cask alexeikaratai/tap/smarttype
```

Then choose **Grant Access…** in SmartType's menu. It restarts and opens **System Settings → Privacy & Security → Accessibility** (**Device Control and Data Access** on macOS 27), where you switch SmartType on. SmartType is ad-hoc signed, so macOS drops the permission with every update; the same button gives it back.

### From GitHub Release

Download `SmartType-x.y.z.zip` from [Releases](https://github.com/alexeikaratai/smarttype/releases), unzip it and move `SmartType.app` to `/Applications`. The app is not notarized, so clear its quarantine flag before the first launch:

```bash
xattr -dr com.apple.quarantine /Applications/SmartType.app
open /Applications/SmartType.app
```

### From Source

With Xcode 26 or later:

```bash
git clone https://github.com/alexeikaratai/smarttype.git
cd smarttype
make run
```

`brew install --formula alexeikaratai/tap/smarttype` builds the same bundle from a release's source.

## 📚 Documentation

| Document | What's inside |
|---|---|
| [Business plan](docs/BUSINESS.md) | Problem, users, competitors, roadmap, business model, risks |
| [Architecture](docs/ARCHITECTURE.md) | Modules, flows, patterns, decisions, diagrams |
| [Delivery plan](docs/DELIVERY.md) | Stages, verification, release and Homebrew distribution |
| [CLAUDE.md](CLAUDE.md) | How work is done here: process, principles, code style |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Setup, commands, conventions, PR checklist |
| [CHANGELOG.md](CHANGELOG.md) | What changed, release by release |

## 🛠️ Requirements

- A Mac with Apple silicon and macOS 14.0+ (Sonoma) to **run** a release; on-device translation needs macOS 26+.
- Swift 6.2+ to **build**: the package declares `swift-tools-version: 6.2`.
- Xcode 26+. The Command Line Tools alone are not enough: they lack `xcstringstool`, which `make app` uses for the Russian strings.

## 👤 Author

**Alex Karatai**

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
