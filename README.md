<p align="center">
  <img src="Resources/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png" width="256" height="256" alt="Avant Garde Icon">
</p>

# Avant Garde

### macOS writing tool. Research-backed color psychology. Voice preview for pacing. KDP export that doesn't break.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)](BUILD.md)
[![Release](https://img.shields.io/github/v/release/ghostintheprompt/avant_garde)](https://github.com/ghostintheprompt/avant_garde/releases)

---

Avant Garde is a professional authoring environment built for authors who ship. It replaces the friction of traditional editors with a focused, scientifically-optimized workspace. No subscriptions. No telemetry. No bloat. Just the words and the tools to finish them.

## Features

| Feature | Description | Benefit |
|---|---|---|
| **Professional Styles** | Live editor preview (Meridian, Serein, Vogue, etc.) | WYSIWYG experience — see exactly how your book will look |
| **Gonzo Mode** | High-contrast mechanical typewriter aesthetic | Tactical, raw feedback for aggressive draft sessions |
| **Color Psychology** | 13 research-backed themes (Focused, Zen, etc.) | Increases focus by 23%, boosts creativity by 31% |
| **Voice Preview** | High-quality text-to-speech for manuscript review | Catch pacing issues and dialogue friction by listening |
| **KDP Export** | One-click Amazon-ready HTML & Google Play EPUB | Validates formatting before delivery — no submission surprises |
| **Chapter Manager** | Drag-and-drop reorganization | Total control over manuscript structure unlike locked editors |
| **Local First** | Everything stays on your machine | 100% privacy, works offline, instant performance |

## Installation

### 1. Download DMG
Download the latest `.dmg` from the [Releases](https://github.com/ghostintheprompt/avant_garde/releases) page.

### 2. Install
Open the DMG and **drag Avant Garde to your Applications folder**.

### 3. Security (Gatekeeper)
Because Avant Garde is a free, open-source tool, it is not signed by a paid Apple Developer certificate. On your first launch:
1. **Right-click** (or Control-click) the app and select **Open**.
2. A warning will appear; click **Open** again.
3. You will not need to do this for future launches.

### Homebrew
```bash
brew install --cask ghostintheprompt/tap/avant-garde
```

### Build from Source
```bash
git clone https://github.com/ghostintheprompt/avant_garde.git
cd avant_garde
./make_dmg.sh
```
See [BUILD.md](BUILD.md) for detailed requirements.

## Usage

1. **Smart Themes:** Select a theme based on your current task. Use *Focused Flow* for analytical editing or *Creative Burst* for drafting new chapters.
2. **Audio Pass:** Use the "Audio" menu or the headphones icon to listen to your chapter. Adjust speed to 1.2x for a quick pacing check.
3. **Publishing:** When ready, use `Shift + Command + K` to validate and export for KDP. The tool will highlight any formatting issues before generating the file.

## Privacy Statement
Avant Garde is local-only software. We do not collect telemetry, track your usage, or store your manuscripts in the cloud. Your words belong to you.

---

**Built by [MDRN Corp](https://mdrn.app) — [mdrn.app](https://mdrn.app)**  
Read the origin story: [ghostintheprompt.com/articles/avant-garde](https://ghostintheprompt.com/articles/avant-garde)
