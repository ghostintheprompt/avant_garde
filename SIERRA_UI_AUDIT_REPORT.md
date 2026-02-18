# AUDIT 1: UI/UX Polish — iPhone + iPad
## Avant Garde Authoring App

**Date:** February 2026
**Standard:** App Store quality, adaptive iPhone + iPad layout
**Status:** PRE-MIGRATION — AppKit-only codebase, iOS requires complete UI rewrite

---

## EXECUTIVE SUMMARY

**Score: 2/10 (iOS readiness)**

The single most important finding of this audit: **Avant Garde is built entirely on AppKit and cannot run on iPhone or iPad at all.** Every UI class — `NSWindow`, `NSViewController`, `NSSplitView`, `NSTableView`, `NSTextView`, `NSAlert`, `NSButton`, `NSFont`, `NSColor` — is macOS-exclusive. There is no partial fix here. Making this app work on iPhone and iPad requires a complete UI layer rewrite.

The good news: the core business logic (converters, parsers, audio engine, models, service container) is largely framework-agnostic and reusable. The foundation is solid. Only the UI layer needs rebuilding.

---

## CRITICAL ISSUES (Launch Blockers)

### C1 — `Package.swift` targets macOS 13.0 only
**File:** `Package.swift:7`
**Severity:** CRITICAL
**Impact:** App literally cannot compile for iOS targets

```swift
// Current — macOS only
platforms: [
    .macOS(.v13)
]

// Required for iPhone + iPad
platforms: [
    .macOS(.v13),
    .iOS(.v16),
]
```

**Fix:** Add `.iOS(.v16)` platform target. Also update all SPM sub-targets to declare their platform support. iOS 16 minimum gives access to SwiftUI APIs needed for a modern authoring experience.

---

### C2 — Entire UI layer is AppKit (NSApplication, NSWindow, NSViewController)
**Files:** `src/EbookConverterApp.swift`, `src/ui/EditorWindowController.swift`, all `src/ui/` files
**Severity:** CRITICAL
**Impact:** 100% of UI code is non-portable

**AppKit classes used (all macOS-only):**
| Class | Count | iOS Replacement |
|-------|-------|-----------------|
| `NSWindow` | 5+ | Not needed (iOS is single-window) |
| `NSWindowController` | 2 | `UIViewController` |
| `NSSplitView` | 1 | `UISplitViewController` |
| `NSTableView` | 1 | `UITableView` / `UICollectionView` |
| `NSTextView` | 1 | `UITextView` |
| `NSAlert` | 15+ | `UIAlertController` |
| `NSOpenPanel` / `NSSavePanel` | 4 | `UIDocumentPickerViewController` |
| `NSButton` | 16+ | `UIButton` |
| `NSTextField` (label) | 10+ | `UILabel` |
| `NSScrollView` | 2 | `UIScrollView` |
| `NSStackView` | 1 | `UIStackView` |
| `NSStoryboard` | 2 | `UIStoryboard` |

**Recommended approach:** Rewrite UI in SwiftUI. It is natively adaptive (iPhone/iPad/Mac), eliminates the AppKit vs UIKit split, and dramatically reduces code duplication.

**Alternative:** Rewrite in UIKit. More work but finer control. Use `UISplitViewController` for iPad sidebar, `UIViewController` + sheets for iPhone.

---

### C3 — `NSColor` used throughout theme system
**File:** `src/ui/ColorThemeManager.swift` (entire file)
**Severity:** CRITICAL
**Impact:** `ColorThemeManager` and all 12 themes will not compile for iOS

All 12 `WritingTheme.colors` return `ThemeColors` with `NSColor` properties. `NSColor` does not exist on iOS.

**Fix:** Replace `NSColor` with `UIColor` (UIKit) or `Color` (SwiftUI). SwiftUI `Color` is cross-platform and the cleanest solution. If keeping UIKit, search/replace `NSColor` → `UIColor` throughout.

---

### C4 — `NSFont` used in FormattingEngine and throughout
**Files:** `src/editor/FormattingEngine.swift:26,124,203,209`, `src/ui/EditorWindowController.swift:219,386,412`
**Severity:** CRITICAL
**Impact:** FormattingEngine won't compile for iOS

`NSFont` is AppKit-only. iOS uses `UIFont`. `NSFontManager` (used for bold/italic toggling in EditorWindowController lines 388-396) has no iOS equivalent.

**Fix:**
- Replace `NSFont` → `UIFont` in UIKit builds
- Use SwiftUI's `.bold()`, `.italic()` modifiers if rewriting in SwiftUI
- For rich text attribute toggling on iOS, use `NSAttributedString` with `UIFont` attributes

---

### C5 — `EbookDocument` subclasses `NSDocument`
**File:** `src/models/EbookDocument.swift:51`
**Severity:** CRITICAL
**Impact:** Document model won't compile for iOS; `NSDocument` is AppKit-only

`NSDocument` provides auto-save, undo management, and file management on macOS. iOS equivalent is `UIDocument`.

**Fix options:**
1. Create a platform-conditional document class:
   ```swift
   #if os(macOS)
   class EbookDocument: NSDocument { ... }
   #else
   class EbookDocument: UIDocument { ... }
   #endif
   ```
2. Better: Strip the document class inheritance entirely. Store document in a plain Swift struct/class, and handle file I/O with a separate `DocumentManager`. This is cleaner and truly cross-platform.

---

### C6 — `makeWindowControllers()` tries to load non-existent "Main" storyboard
**File:** `src/models/EbookDocument.swift:66-71`
**Severity:** CRITICAL
**Impact:** App crashes on launch if storyboard doesn't exist

```swift
override func makeWindowControllers() {
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)  // ← CRASH if Main.storyboard missing
    if let windowController = storyboard.instantiateController(...)...
}
```

There is no `Main.storyboard` in the project (UI is built programmatically). This code path will crash. On iOS, storyboard loading works differently entirely.

**Fix:** Delete this `makeWindowControllers()` override. All window controller creation already happens programmatically in `EbookConverterApp.swift`.

---

## HIGH ISSUES (Polish Blockers)

### H1 — Hardcoded window sizes don't translate to iPhone screens
**File:** `src/ui/EditorWindowController.swift:25,660-661`, `src/EbookConverterApp.swift:27`
**Severity:** HIGH

Window sizes hardcoded at 1200×800 and 800×600 minimum. iPhone 15 Pro is 393pt wide. The entire layout would be clipped and unusable.

**Required adaptive layout approach:**
- iPhone: Single-column, full-screen editor + drawer/sheet for chapter nav
- iPad regular width: Split view (sidebar 280pt + editor)
- iPad compact width: Collapses to iPhone layout

---

### H2 — Formatting toolbar has 16+ items in a flat NSStackView
**File:** `src/ui/EditorWindowController.swift:253-260`
**Severity:** HIGH

The toolbar (Bold, Italic, Underline, 3 alignment buttons, chapter break, image, footnote, KDP validate, Google validate, play, voice settings) cannot fit on iPhone. Even iPad Mini would be tight.

**Required iOS toolbar architecture:**
- iPhone: Primary toolbar with 4-5 essential items + "..." overflow menu
- iPad: Full toolbar as a `UIToolbar` or SwiftUI `ToolbarItemGroup`
- Audio controls: Persistent mini-player at bottom (like Apple Books)
- Format options: Floating format bar that appears on text selection (like Pages)

---

### H3 — No touch target sizing
**File:** `src/ui/EditorWindowController.swift` throughout
**Severity:** HIGH

All macOS buttons are designed for cursor precision. iOS requires minimum 44×44pt touch targets (Apple HIG). Current toolbar buttons are rendered at system default (likely 22-28pt) with 8pt spacing.

**Fix:** All interactive elements on iOS must be at minimum 44×44pt. Use `UIButton` with sufficient padding or `UIEdgeInsets`.

---

### H4 — 15+ `NSAlert` modals must become `UIAlertController`
**Files:** `EbookConverterApp.swift` (12 alerts), `EditorWindowController.swift` (3 alerts)
**Severity:** HIGH

Every `NSAlert().runModal()` is a blocking modal on macOS. iOS equivalent is `UIAlertController` presented asynchronously. All 15+ alert usages must be converted.

Notable patterns that need iOS-specific handling:
- Save confirmation alerts → iOS autosaves, no "saved!" alerts needed
- File format alerts → Share sheet (`UIActivityViewController`)
- Error alerts → `UIAlertController` with `.alert` style

---

### H5 — File access model is incompatible with iOS
**Files:** `EbookConverterApp.swift:247-292` (open), `EbookConverterApp.swift:310-327` (save as)
**Severity:** HIGH

iOS uses the Files app and `UIDocumentPickerViewController` for file access. `NSOpenPanel` and `NSSavePanel` are AppKit-only. The current open/save flow requires a complete rethink:

**iOS document flow:**
- Open: `UIDocumentPickerViewController` or iCloud Drive integration
- Save: Documents stored in app sandbox + `UIDocument` auto-save
- Export: `UIActivityViewController` for sharing HTML/EPUB to Files/AirDrop/Email

---

## MEDIUM ISSUES (Quality Issues)

### M1 — Chapter "break" is plain text, not a data model operation
**File:** `src/ui/EditorWindowController.swift:479-486`
**Severity:** MEDIUM

`insertChapter()` inserts `"\n\n--- Chapter Break ---\n\n"` as literal text. This is not connected to the document model's `chapters` array. On iOS, with UITextView and no NSTextView, this won't render visually distinct at all.

**Fix:** "Add Chapter" should create a new `Chapter` in `document.chapters` and navigate to a new editor view for that chapter.

---

### M2 — No keyboard toolbar for iPhone (software keyboard)
**Severity:** MEDIUM

On iPhone, the software keyboard covers ~40% of the screen. iOS authoring apps need:
- A keyboard accessory toolbar (`UITextView.inputAccessoryView`) with bold/italic/undo
- Auto-scroll to keep cursor above keyboard
- Proper `UIScrollView` keyboard avoidance

---

### M3 — Theme change notification not applied to text view
**File:** `src/ui/ColorThemeManager.swift:199-207`
**Severity:** MEDIUM

`applyTheme()` posts a `.themeDidChange` notification, but `EditorWindowController` has no observer for this notification. The NSTextView's background/text color never actually updates when a theme is selected.

**Fix:** Add `NotificationCenter.default.addObserver` in the editor to update `textView.backgroundColor` and `textView.textColor`.

---

### M4 — Statistics labels never update during typing
**File:** `src/ui/EditorWindowController.swift:643-655`
**Severity:** MEDIUM

`updateStatistics()` is only called in `addChapter()`. The sidebar word count, character count, and reading time labels stay at "0" while the user types.

**Fix:** Set `NSTextView.delegate = self` (macOS) or `UITextView.delegate = self` (iOS) and call `updateStatistics()` in `textViewDidChange(_:)`.

---

### M5 — No empty state UI
**Severity:** MEDIUM

New document opens to a blank `NSTextView`/`UITextView` with no placeholder text, no onboarding, no hints. First-time users on iPhone will see a white box with a cursor and nothing else.

**Fix:** Add placeholder text ("Start writing your story...") that disappears on first keystroke, and a brief onboarding card for new installs.

---

## LOW ISSUES (Nice to Have)

### L1 — No Dynamic Type support
**Severity:** LOW
Apple requires Dynamic Type support for App Store accessibility compliance. All text sizes must scale with user's preferred text size setting.

### L2 — No Dark Mode in iOS theme system
**Severity:** LOW
The 12 writing themes are fixed colors. They need light/dark mode variants, or should respect the system appearance and only modify the accent/background tint.

### L3 — No haptic feedback
**Severity:** LOW
iOS users expect `UIImpactFeedbackGenerator` haptics on formatting actions, chapter creation, and export completion.

### L4 — No iPad keyboard shortcut support
**Severity:** LOW
iPad + Magic Keyboard users expect keyboard shortcuts. Define `UIKeyCommand` equivalents for Bold (⌘B), Italic (⌘I), New Chapter (⌘N), Export (⌘E).

---

## RECOMMENDED iOS LAYOUT ARCHITECTURE

### iPhone Layout
```
┌─────────────────────────┐
│ [≡ Chapters] [Book Title] [···] │  Navigation bar
├─────────────────────────┤
│                         │
│   Writing area          │  UITextView, full screen
│   (UITextView)          │
│                         │
│                         │
├─────────────────────────┤
│ [B][I][U] [⌂][⟵]  [▶] │  Keyboard accessory bar
└─────────────────────────┘
     ↑ Software keyboard

Chapter nav → slide-in drawer (UISheetPresentationController)
Export → UIActivityViewController share sheet
Settings → UINavigationController pushed view
```

### iPad Layout
```
┌───────────────┬─────────────────────────────┐
│ Chapters      │ [B][I][U]|[⌂][¶]|[KDP][G]|[▶][🎙] │
│               ├─────────────────────────────┤
│ • Chapter 1   │                             │
│ • Chapter 2   │   Writing area              │
│ • Chapter 3   │   (UITextView, fluid)       │
│               │                             │
│ [+ Add Ch.]   │                             │
│               │                             │
│ ─────────────│                             │
│ Words: 2,340  │                             │
│ Read: 12 min  ├─────────────────────────────┤
│               │ Format: Universal  ✅ Ready │
└───────────────┴─────────────────────────────┘
UISplitViewController with compact/regular size class
```

---

## MIGRATION EFFORT ESTIMATE

| Area | Effort |
|------|--------|
| Package.swift + project setup (Xcode) | Small |
| Port models (EbookDocument → UIDocument or plain class) | Medium |
| Port ColorThemeManager (NSColor → UIColor/Color) | Small |
| Port FormattingEngine (NSFont → UIFont) | Small |
| Rewrite EditorWindowController → SwiftUI View | Large |
| Rewrite all NSAlerts → UIAlertController | Medium |
| Rewrite file open/save/export → UIDocumentPicker/UIActivityVC | Medium |
| iPhone adaptive layout | Large |
| iPad split view | Medium |
| Keyboard accessory view | Small |
| Chapter navigation drawer | Medium |
| Audio session setup for iOS (AVAudioSession) | Small |
| **Total UI rewrite** | **~40-60 hours** |

The core logic (converters, parsers, audio TTS logic, service container, models data) can be reused with minor modifications (~5-10 hours of adaptation).
