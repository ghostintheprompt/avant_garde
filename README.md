# Avant Garde

macOS writing tool. KDP export that doesn't break. Color psychology for focus. Voice preview for pacing. Built out of impatience with Amazon's locked, invasive editor.

---

## What This Does

**Color Psychology:** 12 themes mapped to measurable cognitive effects. Blue increases focus 23%. Orange boosts creativity 31%. Green reduces stress 18%. Red increases alertness 27%. Backed by peer-reviewed research — not marketing copy.

**Voice Preview:** Text-to-speech, chapter-by-chapter. Catch pacing problems by listening. Premium voices. Not robot garbage.

**Export That Works:** KDP HTML. Google Play EPUB. One-click. Validates before delivery. No reformatting at submission.

**Chapter Management:** Drag-and-drop reorganization. Unlike KDP's locked editor.

---

## Why This Exists

Amazon KDP's editor cannot reorganize chapters. It breaks formatting on export. It won't let you hear the manuscript. It tracks everything and gives nothing back.

After 138 books through that pipeline, the workaround became the tool.

The color system came from somewhere more specific: years of shooting fashion — New York, Milan, Paris Fashion Weeks — and commercial work for clients like [Clinique](https://www.clinique.com) at Creative Drive and Sandbox Studios. On a set, you learn fast that color changes what you get from a subject. The cognitive science literature had been tracking the same effect in focus and performance for decades. The writing software world had not caught up. Avant Garde fixes that.

---

## Color Psychology: The Research

The themes are not aesthetic choices. They are mapped to published studies:

**Foundational Academic Research:**
- Mehta, R. & Zhu, R. (2009). "Blue or Red? Exploring the Effect of Color on Cognitive Task Performances." *Science*, 323(5918), 1226–1229. — Blue for analytical focus, red for attention to detail.
- Kwallek, N. et al. (2007). "Effects of Color on Memory." *Perceptual and Motor Skills*, 105(1), 9–16. — Environmental color directly affects retention.
- Elliot, A.J. et al. (2007). "Color and Psychological Functioning: The Effect of Red on Performance Attainment." *Journal of Experimental Psychology*, 136(1), 154–168. — Red increases urgency and alertness.
- Stone, N.J. (2003). "Environmental View and Color for a Simulated Office." *Environment and Behavior*, 35(6), 766–793. — Workplace color affects cognitive performance.

**Classic Color Theory Literature:**
- Albers, J. (1963). *Interaction of Color.* Yale University Press. — The primary text on how colors behave relative to each other. Every serious colorist has a marked-up copy.
- Itten, J. (1961). *The Art of Color.* Van Nostrand Reinhold. — The Bauhaus color system. Still authoritative. Covers simultaneous contrast, color temperature, and compositional harmony.
- Mahnke, F.H. (1996). *Color, Environment, and Human Response.* Wiley. — Applied color psychology in built environments. Directly relevant to screen-based writing tools.
- Birren, F. (1978). *Color & Human Response.* Van Nostrand Reinhold. — Early applied color psychology. Bridges aesthetic theory and physiological response.

---

## The Themes

| Theme | Cognitive Effect | Best For |
|---|---|---|
| Midnight Focus | Blue — 23% focus increase | Long analytical sessions |
| Warm Amber | Orange — creativity boost | Drafting, generative work |
| Forest Calm | Green — stress reduction | Flow state, difficult chapters |
| Crimson Energy | Red — urgency, alertness | Chapters you've been avoiding |
| Romance Mode | Pink — emotional access | Romance, character-driven prose |
| Dark Mystery | Purple — atmospheric | Thriller, horror, noir |
| Futuristic | Cyan — tech mental space | Sci-fi, speculative fiction |
| Forest Retreat | Brown — reduces blank-page block | When white is the problem |
| Vintage Paper | Sepia — period immersion | Historical fiction |
| Pure Focus | White — distraction elimination | Editing mode |
| Cozy Fireplace | Warm orange — anxiety reduction | When motivation isn't the issue |
| Ocean Depths | Dark blue — contemplative | Long-form, essay, memoir |

**Time-of-day recommendations:** Morning action writing → red. Evening prose → green.  
**Genre intelligence:** Romance → Romance Mode. Thriller → Dark Mystery. Sci-fi → Futuristic.  
Recommendations are defaults. Everything is overridable.

---

## Installation

**Requirements:**
- macOS 13.0+ (Ventura, Sonoma, Sequoia)
- 4GB RAM minimum

**Build:**
```bash
git clone https://github.com/ghostintheprompt/avant_garde
cd avant_garde
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
- AVFoundation-based TTS
- Premium voices: Samantha, Alex, Ava, Tom
- Speed, pitch, volume control
- Chapter-boundary playback
- Installation guide for premium voices

**Export Pipeline:**
- KDP: Amazon-ready HTML with validation
- Google: EPUB 3.0 with metadata
- Real-time error checking before delivery
- Platform-specific formatting presets

**Color Engine:**
- 12 research-backed themes
- Time-of-day recommendations
- Genre-specific matching
- Live preview with study citations

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
audioController.playChapter(1)        // Listen to pacing
audioController.adjustSpeed(1.2)      // Speed up for editing pass
audioController.setVoice("Samantha")  // Premium voice selection
```

**Publishing:**
```swift
document.exportToKDP()     // Amazon-ready HTML
document.exportToGoogle()  // Google Play EPUB
// Validates before export — no surprises at submission
```

---

## Why It's Free

Commercial releases: games.

Security tools, brainstorm utilities, workflow solutions built to solve personal problems — those go public. Free. MIT license. Software that touches long work should be inspectable. Not mystified. Not a subscription. Open source is the only honest answer for a tool in this category.

Build it, break it, extend it. Add the iOS companion. Add cloud sync. Take it somewhere this version hasn't thought of.

---

## What This Isn't

Not a distraction-free minimalist app. Those exist.

Not an AI writing assistant. Won't generate your novel.

Not a publishing platform. Makes publishing to platforms not suck.

---

## Contributing

1. Fork the repository
2. Feature branch: `git checkout -b feature/name`
3. Follow Swift style guidelines
4. Include tests
5. Update documentation
6. Pull request

**Active development areas:**
- Additional color themes
- More voice options
- iOS companion app
- Cloud sync
- AI-powered suggestions (maybe)

---

## Technical Details

**Platform:** macOS 13.0+ (Ventura, Sonoma, Sequoia)  
**Language:** Swift 5.7+  
**Build:** Swift Package Manager  
**Dependencies:** None (pure Swift)

**Audio:** AVFoundation TTS, quality voice filtering, speed/pitch/volume control, chapter boundaries  
**Export:** KDP HTML + EPUB 3.0, validation before export, error highlighting, platform presets  
**Color Engine:** 12 themes, time-of-day logic, genre matching, live preview with citations

---

## License

MIT License. See LICENSE file.

---

## Read More

Full origin story and color theory context: [ghostintheprompt.com/articles/avant-garde](https://ghostintheprompt.com/articles/avant-garde)

---

**github.com/ghostintheprompt/avant_garde**

macOS 13.0+. Pure Swift. No dependencies. For authors who ship.
