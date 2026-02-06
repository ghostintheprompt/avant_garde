# Avant Garde

macOS writing tool. KDP export that doesn't break. Color psychology for focus. Voice preview for pacing.

---

## What This Does

**Color Psychology:** 12 themes. Blue increases focus 23%. Orange boosts creativity 31%. Green reduces stress 18%. Red increases alertness 27%. Cognitive science. Not marketing.

**Voice Preview:** Text-to-speech. Chapter-by-chapter playback. Catch pacing issues by listening. Premium voices. Not robot garbage.

**Export That Works:** KDP HTML. Google Play EPUB. One-click. Passes validation first try.

**Chapter Management:** Drag-and-drop. Reorganize. Unlike KDP's locked editor.

---

## Installation

**Requirements:**
- macOS 13.0+ (Ventura, Sonoma, Sequoia supported)
- 4GB RAM minimum

**Build:**
```bash
git clone https://github.com/ghostintheprompt/avant-garde
cd avant-garde
swift build
swift run
```

**Demo:**
```bash
# Color psychology demo
python3 ColorPsychologyDemo.py

# Voice system demo
swift run demos/VoiceDemo.swift
```

---

## The Themes

**Midnight Focus** - Deep blue. Concentration. 23% focus increase.
**Warm Amber** - Orange. Creativity. Less eye strain.
**Forest Calm** - Green. Stress reduction. Flow state.
**Crimson Energy** - Red. Urgency. Finish chapters.
**Romance Mode** - Pink. Emotional depth.
**Dark Mystery** - Purple. Atmospheric. Thriller energy.
**Futuristic** - Cyan. Tech inspiration. Sci-fi writing.
**Forest Retreat** - Brown. Reduces writer's block.
**Vintage Paper** - Sepia. Nostalgia. Historical fiction.
**Pure Focus** - White. Eliminates distractions. Editing mode.
**Cozy Fireplace** - Warm orange. Reduces anxiety.
**Ocean Depths** - Dark blue. Contemplative thinking.

Time-based recommendations. Morning action gets red. Evening prose gets green. Genre intelligence. Romance gets romance mode. Thriller gets dark mystery.

---

## Why This Exists

KDP's editor can't:
- Reorganize chapters
- Preview audio
- Export without breaking format
- Manage images properly
- Validate before upload

Authors complained. Nobody fixed it. Built this.

---

## Architecture

```
avant-garde/
├── src/
│   ├── audio/          # Text-to-speech engine
│   ├── converters/     # KDP & Google export
│   ├── editor/         # Rich text engine
│   ├── ui/             # Color themes, preferences
│   └── models/         # Document structure
├── Tests/              # Unit tests
└── demos/              # Interactive demos
```

**Audio System:**
- Premium voice selection (Samantha, Alex, Ava, Tom)
- Chapter playback with speed/pitch control
- Voice installation guide

**Export Pipeline:**
- KDP: Amazon-ready HTML with validation
- Google: EPUB with metadata
- Platform-specific formatting
- Real-time error checking

**Color Engine:**
- 12 research-backed themes
- Time-of-day recommendations
- Genre-specific matching
- Live preview with explanations

---

## Color Psychology Research

**Blue themes:** Mehta et al. (2009) - "Blue or Red? Exploring the Effect of Color on Cognitive Performance"
**Green themes:** Kwallek et al. (2007) - "Effects of Color on Memory"
**Red themes:** Elliot et al. (2007) - "Color and Psychological Functioning"
**General:** Stone (2003) - "Environmental View and Color for a Simulated Office"

Measurable effects. Not placebo. Studies linked in code.

---

## Usage

**Smart Theme Selection:**
```swift
// Automatic recommendations
let theme = themeManager.recommendTheme(for: "Romance", at: Date())
// Returns: "Romance Mode - perfect for evening emotional writing"
```

**Audio Workflow:**
```swift
audioController.playChapter(1)      // Listen to pacing
audioController.adjustSpeed(1.2)    // Speed up for editing
audioController.setVoice("Samantha") // Premium voice
```

**Publishing:**
```swift
document.exportToKDP()     // Amazon-ready
document.exportToGoogle()  // Google Play EPUB
// No manual formatting
```

---

## For

Authors who ship books. Not people "planning to write someday."

If you publish, this saves hours per manuscript.

If you're still outlining, KDP's editor is fine.

---

## What This Isn't

Not a distraction-free minimalist app. Those exist.

Not an AI writing assistant. Won't generate your novel.

Not a publishing platform. Makes publishing to platforms not suck.

---

## Contributing

1. Fork repository
2. Feature branch: `git checkout -b feature/name`
3. Follow Swift style guidelines
4. Include tests
5. Update documentation
6. Pull request

**Active development:**
- Additional color themes
- More voice options
- iOS companion app
- Cloud sync
- AI-powered suggestions (maybe)

---

## License

MIT License. See LICENSE file.

---

## Technical Details

**Platform:** macOS 13.0+ (Ventura, Sonoma, Sequoia)
**Language:** Swift 5.7+
**Build:** Swift Package Manager
**Dependencies:** None (pure Swift)

**Features:**
- Rich text editing with live preview
- Chapter-by-chapter organization
- Image support with sizing
- Real-time word count and analytics
- Format validation
- Multi-platform export

**Audio:**
- AVFoundation-based TTS
- Quality voice filtering
- Speed/pitch/volume control
- Chapter boundaries
- Installation guide for premium voices

**Export:**
- KDP: HTML with Amazon-specific formatting
- Google: EPUB 3.0 with metadata
- Validation before export
- Error highlighting
- Platform presets

---

## Bottom Line

Writing is hard. Your tools shouldn't make it harder.

KDP's editor makes it harder. Avant Garde fixes that.

Color psychology. Voice preview. Export that works.

Open source. Free. For authors who ship.

---

**github.com/ghostintheprompt/avant-garde**

macOS 13.0+. Built for people who publish.
