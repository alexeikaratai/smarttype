.PHONY: help build test clean icon app run install fix bump version-check docs-check footprint l10n l10n-check doctor actions-check logs format lint coverage

.DEFAULT_GOAL := help

# === Config ===
APP_NAME     := SmartType
BUNDLE_ID    := com.smarttype.app
VERSION      := 0.1.0
BUILD_DIR    := .build/release
APP_DIR      := build/$(APP_NAME).app
CONTENTS     := $(APP_DIR)/Contents
MACOS_DIR    := $(CONTENTS)/MacOS
RESOURCES    := $(CONTENTS)/Resources
# Ad-hoc, as releases are. A stable identity keeps the Accessibility grant across rebuilds
# while developing:  make app SIGN_ID="Apple Development: …"  (or its SHA-1 hash).
SIGN_ID      ?= -
CATALOG      := Resources/Localizable.xcstrings
# Drawn by scripts/generate-icon.swift, never committed (*.icns is in .gitignore).
ICON         := Resources/AppIcon.icns
L10N_TMP     := .build/l10n

# === Build ===

build:
	@echo "🔨 Building $(APP_NAME)..."
	swift build -c release

test:
	@echo "🧪 Running tests..."
	swift test

# === Formatting & Linting ===
# swift-format ships inside the Xcode toolchain — reached via xcrun, never a bare
# `swift-format` (not on PATH) and never `swift format` (absent before Swift 6.2).
# Rules live in .swift-format (the same as SmartDock); `lint` is what CI gates on.

SWIFT_FORMAT := xcrun swift-format
SWIFT_SOURCES := Sources Tests

format:
	@echo "🎨 Formatting Swift sources..."
	@$(SWIFT_FORMAT) format --in-place --recursive $(SWIFT_SOURCES)
	@echo "✅ Formatted"

lint:
	@echo "🔎 Linting Swift sources..."
	@$(SWIFT_FORMAT) lint --strict --recursive $(SWIFT_SOURCES) && \
		echo "✅ No violations" || \
		{ echo "❌ Formatting violations — run: make format"; exit 1; }

# === Coverage ===
# A per-file table for the library targets. The SmartType executable (main.swift) is not
# linked into the test bundle, so it never appears here.
#
# The test bundle is located, not named: up to Swift 6.3 SPM names it after the package
# (SmartTypePackageTests.xctest), from Swift 6.4 after the test target. The binary inside
# always carries the bundle's own name, so deriving it from whatever *.xctest exists
# serves both — CI runs Xcode 26, the dev machine Xcode 27.

coverage:
	@echo "🧪 Running tests with coverage..."
	@swift test --enable-code-coverage
	@echo ""
	@set -e; \
	bin=$$(swift build --show-bin-path); \
	prof=$$(swift test --show-codecov-path); \
	bundle=$$(ls -d "$$bin"/*.xctest 2>/dev/null | head -1); \
	if [ -z "$$bundle" ]; then \
		echo "❌ No .xctest bundle in $$bin — did the test build change layout again?"; \
		exit 1; \
	fi; \
	binary="$$bundle/Contents/MacOS/$$(basename "$$bundle" .xctest)"; \
	xcrun llvm-cov report \
		"$$binary" \
		-instr-profile="$$(dirname $$prof)/default.profdata" \
		-ignore-filename-regex='.build|Tests/'

# === Localization ===
# UI strings are `String(localized:)` with English keys; the Russian translation lives in
# the String Catalog. Apple's tools do the work: `extract` finds every key in the sources,
# `sync` adds new keys to the catalog and marks vanished ones stale, and `compile` (in
# `app`) turns the catalog into <lang>.lproj inside the bundle. Not a SwiftPM resource:
# Bundle.module would break the bundle's signature. Extraction runs per target, so two
# files with the same name in different targets cannot overwrite each other's keys.

L10N_EXTRACT = rm -rf $(L10N_TMP); \
	for target in Sources/*/; do \
		out=$(L10N_TMP)/$$(basename $$target); mkdir -p $$out; \
		xcrun xcstringstool extract --modern-localizable-strings \
			$$(find $$target -name '*.swift') --output-directory $$out > /dev/null; \
	done

l10n:
	@echo "🌐 Syncing $(CATALOG) with the sources..."
	@set -e; $(L10N_EXTRACT); \
	xcrun xcstringstool sync $(CATALOG) --stringsdata $$(find $(L10N_TMP) -name '*.stringsdata')
	@echo "✅ Synced — translate any new key into Russian, then run: make l10n-check"

# Every key is a plain literal and in the catalog, nothing in the catalog is stale, and every
# key has a Russian translation. `app` runs this first, so an untranslated string cannot ship.
# The script reads the sources itself: CI's older Xcode needs nothing beyond Swift.
l10n-check:
	@echo "🌐 Checking translations..."
	@swift scripts/l10n-check.swift $(CATALOG) Sources

# === App Bundle ===

# Redrawn only when the script changes.
$(ICON): scripts/generate-icon.swift
	@echo "🎨 Drawing the app icon..."
	@swift scripts/generate-icon.swift $(ICON)

icon: $(ICON)

app: build l10n-check $(ICON)
	@echo "📦 Creating $(APP_NAME).app bundle..."
	@rm -rf $(APP_DIR)
	@mkdir -p $(MACOS_DIR) $(RESOURCES)
	cp $(BUILD_DIR)/$(APP_NAME) $(MACOS_DIR)/$(APP_NAME)
	@plutil -lint Resources/Info.plist > /dev/null
	cp Resources/Info.plist $(CONTENTS)/Info.plist
	cp $(ICON) $(RESOURCES)/AppIcon.icns
	@# ru.lproj, where String(localized:) finds Russian at run time; the English strings are the keys.
	xcrun xcstringstool compile $(CATALOG) --output-directory $(RESOURCES) > /dev/null
	codesign --force --sign "$(SIGN_ID)" $(APP_DIR)
	@codesign --verify --strict $(APP_DIR)
	@echo "✅ $(APP_DIR) created (signed with: $(SIGN_ID))"
	@echo "   Run: make run"

# === Run & Install ===
# The previous instance is stopped and waited for, then the new build is opened with
# `open -n`. A plain `open` hands the launch to an instance LaunchServices still believes is
# running — even shortly after its process has exited — so the new build never starts and
# nothing is left running (measured: one launch in three failed even after the wait).

STOP_RUNNING = pkill -x $(APP_NAME) 2>/dev/null || true; \
	for attempt in $$(seq 50); do pgrep -x $(APP_NAME) > /dev/null || break; sleep 0.1; done

run: app
	@echo "🚀 Launching $(APP_NAME)..."
	@$(STOP_RUNNING)
	open -n $(APP_DIR)

install: app
	@echo "📲 Installing to /Applications..."
	@$(STOP_RUNNING)
	@rm -rf /Applications/$(APP_NAME).app
	cp -R $(APP_DIR) /Applications/$(APP_NAME).app
	@# macOS discovers Services (the right-click commands) from installed bundles;
	@# refresh the registry now rather than at the next login.
	/System/Library/CoreServices/pbs -update
	@echo "✅ Installed to /Applications/$(APP_NAME).app"

fix:
	@echo "🔧 Fixing Gatekeeper quarantine..."
	xattr -cr /Applications/$(APP_NAME).app
	codesign --force --deep --sign - /Applications/$(APP_NAME).app
	@echo "✅ Fixed. Run: open /Applications/$(APP_NAME).app"

# === Clean ===

clean:
	@echo "🧹 Cleaning..."
	swift package clean
	rm -rf build/ $(ICON)

# === Version ===
# Usage: make bump V=1.2.3
#
# The single entry point for changing the version. Updates every place it is written:
#   Makefile            VERSION := x.y.z          (source of truth)
#   Info.plist          CFBundleShortVersionString + CFBundleVersion (build, +1)
#   README.md           shields.io badge URL + its alt text
#   CHANGELOG.md        opens a dated section for the version under [Unreleased]
# Then runs version-check, so a missed spot fails loudly instead of shipping stale.
# The release workflow calls this target too — never duplicate the sed logic there.

bump:
ifndef V
	$(error Usage: make bump V=1.2.3)
endif
	@echo "📌 Bumping version to $(V)..."
	sed -i '' 's/^VERSION      := .*/VERSION      := $(V)/' Makefile
	sed -i '' '/CFBundleShortVersionString/{n;s|<string>.*</string>|<string>$(V)</string>|;}' Resources/Info.plist
	@BUILD=$$(sed -n '/CFBundleVersion/{n;s/.*<string>\(.*\)<\/string>.*/\1/p;}' Resources/Info.plist) && \
		NEW_BUILD=$$(( $$BUILD + 1 )) && \
		sed -i '' "/CFBundleVersion/{n;s|<string>.*</string>|<string>$$NEW_BUILD</string>|;}" Resources/Info.plist
	sed -i '' -e 's|badge/version-[0-9][0-9.]*-|badge/version-$(V)-|' \
	          -e 's|alt="Version [0-9][0-9.]*"|alt="Version $(V)"|' README.md
	@# Open a dated section directly under [Unreleased], so whatever accumulated there
	@# becomes this version's notes. Skipped when the section exists: re-running is harmless.
	@if ! grep -q '^## \[$(V)\]' CHANGELOG.md; then \
		awk -v ver='$(V)' -v today="$$(date +%Y-%m-%d)" \
			'{ print } /^## \[Unreleased\]$$/ { print ""; print "## [" ver "] — " today }' \
			CHANGELOG.md > CHANGELOG.md.tmp && mv CHANGELOG.md.tmp CHANGELOG.md; \
		echo "  📝 CHANGELOG: opened section [$(V)]"; \
	fi
	@$(MAKE) --no-print-directory version-check
	@echo "✅ Version: $(V), Build: $$(sed -n '/CFBundleVersion/{n;s/.*<string>\(.*\)<\/string>.*/\1/p;}' Resources/Info.plist)"

# Every version reference must match VERSION. Before the first release the CHANGELOG has
# no dated section yet; that state is reported as unreleased rather than failed.
version-check:
	@echo "🔎 Version references (expected $(VERSION)):"
	@plist=$$(sed -n '/CFBundleShortVersionString/{n;s/.*<string>\(.*\)<\/string>.*/\1/p;}' Resources/Info.plist); \
	badge=$$(sed -n 's|.*badge/version-\([0-9][0-9.]*\)-.*|\1|p' README.md | head -1); \
	alt=$$(sed -n 's|.*alt="Version \([0-9][0-9.]*\)".*|\1|p' README.md | head -1); \
	changelog=$$(sed -n 's|^## \[\([0-9][0-9.]*\)\].*|\1|p' CHANGELOG.md | head -1); \
	fail=0; \
	for entry in "Info.plist:$$plist" "README badge:$$badge" "README alt:$$alt"; do \
		name="$${entry%%:*}"; value="$${entry##*:}"; \
		if [ "$$value" = "$(VERSION)" ]; then \
			printf "  ✅ %-14s %s\n" "$$name" "$$value"; \
		else \
			printf "  ❌ %-14s %s\n" "$$name" "$${value:-<not found>}"; \
			fail=1; \
		fi; \
	done; \
	if [ -z "$$changelog" ]; then \
		printf "  ⏳ %-14s %s\n" "CHANGELOG" "unreleased — no dated section yet"; \
	elif [ "$$changelog" = "$(VERSION)" ]; then \
		printf "  ✅ %-14s %s\n" "CHANGELOG" "$$changelog"; \
	else \
		printf "  ❌ %-14s %s\n" "CHANGELOG" "$$changelog"; \
		fail=1; \
	fi; \
	if [ $$fail -eq 1 ]; then \
		echo "❌ Version mismatch — run: make bump V=$(VERSION)"; \
		exit 1; \
	fi
	@dupes=$$(grep -oE '^## \[[0-9][0-9.]*\]' CHANGELOG.md | sort | uniq -d | tr -d '#[] ' | tr '\n' ' '); \
	if [ -n "$$dupes" ]; then \
		printf "  ❌ %-14s duplicated: %s\n" "CHANGELOG" "$$dupes"; \
		echo "❌ A version may only have one section"; \
		exit 1; \
	fi

# === Checks ===

# Every relative link and anchor in the Markdown resolves, and CLAUDE.md's file table lists
# exactly the Swift files under Sources/. A Swift script, like SmartDock's generate-icon, so
# the check needs nothing beyond the toolchain.
docs-check:
	@echo "📚 Checking docs..."
	@swift scripts/docs-check.swift

# The idle cost of the running app, against the budget in docs/ARCHITECTURE.md §1: 0.0% CPU,
# no idle wakeups, a small footprint. top's IDLEW is a running total since launch, so the
# wakeups reported are the growth between two samples ten seconds apart, not the total.
footprint:
	@pid=$$(pgrep -x $(APP_NAME)) || { echo "❌ $(APP_NAME) is not running — make run first"; exit 1; }; \
	echo "📏 $(APP_NAME) [$$pid], idle for 10 s:"; \
	top -l 2 -s 10 -pid $$pid -stats cpu,idlew,threads,mem | \
		awk 'NF == 4 && $$1 ~ /^[0-9.]+$$/ { n++; cpu = $$1; wakeups[n] = $$2; threads = $$3; memory = $$4 } \
			END { printf "  CPU %s%%  idle wakeups %d  threads %s  memory %s\n", cpu, wakeups[n] - wakeups[1], threads, memory }'; \
	footprint $$pid | awk '/phys_footprint:/ { printf "  footprint %s %s\n", $$2, $$3 }'

# === Tooling ===

doctor:
	@echo "🩺 Checking dev environment..."
	@echo ""
	@printf "  Swift:       "; command -v swift >/dev/null && swift --version 2>/dev/null | head -1 || echo "❌ not installed"
	@printf "  Xcode:       "; command -v xcodebuild >/dev/null && xcodebuild -version | head -1 || echo "❌ not installed"
	@printf "  swift-format:"; xcrun --find swift-format >/dev/null 2>&1 && echo " ✅ available" || echo " ❌ not in toolchain (needs Xcode 26+)"
	@printf "  llvm-cov:    "; xcrun --find llvm-cov >/dev/null 2>&1 && echo "✅ available" || echo "❌ not in toolchain"
	@printf "  codesign:    "; command -v codesign >/dev/null && echo "✅ available" || echo "❌ not installed"
	@printf "  gh:          "; command -v gh >/dev/null && gh --version | head -1 || echo "❌ not installed (brew install gh)"
	@printf "  git:         "; command -v git >/dev/null && git --version || echo "❌ not installed"
	@echo ""
	@echo "  Project version: $(VERSION)"
	@echo "  Working tree:    $$(git status --porcelain | wc -l | tr -d ' ') uncommitted change(s)"

actions-check:
	@echo "🔎 Checking GitHub Actions versions..."
	@echo ""
	@command -v gh >/dev/null || { echo "❌ gh CLI not installed (brew install gh)"; exit 1; }
	@printf "%-35s %-12s %-12s %s\n" "ACTION" "CURRENT" "LATEST" "STATUS"
	@printf "%-35s %-12s %-12s %s\n" "------" "-------" "------" "------"
	@for line in $$(grep -h "uses: " .github/workflows/*.yml | sed 's/.*uses: //' | sort -u); do \
		action=$$(echo $$line | cut -d@ -f1); \
		current=$$(echo $$line | cut -d@ -f2); \
		latest=$$(gh api repos/$$action/releases/latest --jq .tag_name 2>/dev/null || echo "n/a"); \
		current_major=$$(echo $$current | sed 's/^v//' | cut -d. -f1); \
		latest_major=$$(echo $$latest | sed 's/^v//' | cut -d. -f1); \
		if [ "$$latest" = "n/a" ]; then \
			status="?"; \
		elif [ "$$current" = "$$latest" ]; then \
			status="✅ up-to-date"; \
		elif [ "$$current_major" = "$$latest_major" ]; then \
			status="✅ up-to-date (major pinned)"; \
		else \
			status="⬆️  major update: $$current → $$latest"; \
		fi; \
		printf "%-35s %-12s %-12s %s\n" "$$action" "$$current" "$$latest" "$$status"; \
	done

logs:
	@echo "📜 Streaming $(APP_NAME) logs (Ctrl+C to stop)..."
	@/usr/bin/log stream --predicate 'subsystem == "$(BUNDLE_ID)"' --info --style compact

# === Help ===

help:
	@echo ""
	@echo "📚 $(APP_NAME) — Makefile commands"
	@echo ""
	@echo "  Build & Run:"
	@echo "    make build         Build release binary"
	@echo "    make test          Run unit tests"
	@echo "    make app           Build .app bundle (ad-hoc signed; SIGN_ID=… for a stable identity)"
	@echo "    make run           Build + open the app (stops a running one first)"
	@echo "    make icon          Draw the app icon (make app does it when the script changed)"
	@echo "    make clean         Remove all build artifacts"
	@echo ""
	@echo "  Code quality:"
	@echo "    make format        Reformat Swift sources in place (swift-format)"
	@echo "    make lint          Check formatting without writing — CI gates on this"
	@echo "    make coverage      Run tests and print a per-file coverage table"
	@echo ""
	@echo "  Install:"
	@echo "    make install       Copy .app to /Applications and refresh Services"
	@echo "    make fix           Fix Gatekeeper quarantine on /Applications/$(APP_NAME).app"
	@echo ""
	@echo "  Version:"
	@echo "    make bump V=1.2.3  Bump version everywhere (Makefile, Info.plist, README badge, CHANGELOG)"
	@echo "    make version-check Verify all version references agree"
	@echo ""
	@echo "  Localization:"
	@echo "    make l10n          Add new UI strings to the catalog (then translate them)"
	@echo "    make l10n-check    Verify every UI string is in the catalog and translated"
	@echo ""
	@echo "  Checks:"
	@echo "    make docs-check    Verify links, anchors and the CLAUDE.md file table"
	@echo "    make footprint     Idle CPU, wakeups and memory of the running app"
	@echo ""
	@echo "  Tooling:"
	@echo "    make doctor        Verify dev environment (swift, xcode, gh)"
	@echo "    make actions-check Compare GitHub Actions versions vs latest (requires gh)"
	@echo "    make logs          Stream live $(APP_NAME) logs (Ctrl+C to stop)"
	@echo ""
	@echo "  Current version: $(VERSION)"
	@echo ""
