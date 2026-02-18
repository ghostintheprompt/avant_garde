# AUDIT 2: App Engagement & User Flow
## Avant Garde Authoring App

**Date:** February 2026
**Focus:** Core user journey, feature discovery, retention, workflow friction
**Note:** This audit replaces "Game Economy" with "App Engagement" — the equivalent analysis for a productivity app.

---

## EXECUTIVE SUMMARY

**Score: 5/10**

Avant Garde has a genuinely useful core value proposition (write → validate → export for KDP/Google). The business logic is solid. But the user flow has significant gaps: there's no onboarding, critical features are buried in menus, the chapter model is disconnected from the editor, and the export flow doesn't leverage iOS sharing conventions. The app's best features (12 themes, TTS proofing, dual-platform export) are invisible to new users.

---

## CORE USER JOURNEY ANALYSIS

### The Author's Loop (Target Flow)
```
Write Chapter → Review with TTS → Check Formatting → Export → Publish
     ↑__________________↑
```

This is a solid, linear workflow. Unlike a game, there's no need for artificial retention loops — the value is professional. But the current implementation **breaks the loop at every handoff**.

---

## CRITICAL FLOW ISSUES

### CF1 — No Onboarding: First Launch is a Blank White Box
**Severity:** CRITICAL

New users launch the app and see an empty `NSTextView` (or its iOS equivalent). No introduction, no tutorial, no template, no hint about what to do next.

**What professional iOS writing apps do:**
- iA Writer: Shows template picker on first launch
- Ulysses: Shows "Getting Started" sheet
- Apple Notes: Auto-creates a welcome note

**Required for iOS launch:**
1. First-launch modal: "Welcome to Avant Garde — Start writing your book"
2. Template picker: "Fiction Novel" / "Non-fiction Book" / "Blank"
3. Brief 3-step onboarding: "Write → Validate → Export"
4. Persistent empty-state hint: "Tap to start writing Chapter 1"

---

### CF2 — The Three Best Features Are Invisible
**Severity:** CRITICAL

On macOS, the app's three killer features are buried:
- **12 Writing Themes**: View menu → Color Themes submenu (3 clicks, never discovered)
- **TTS Proofing**: Audio menu → Play Current Chapter (users don't know this exists)
- **Dual Export**: File menu (users assume "Export" means one format)

On iPhone, **there is no menu bar**. All these features must be surfaced in the UI.

**Required iOS feature surfacing:**
| Feature | Current (macOS) | Required (iOS) |
|---------|----------------|----------------|
| Themes | View menu | Persistent button in navigation bar with visual preview |
| TTS | Audio menu | Always-visible ▶/⏸ controls at bottom |
| KDP Export | File menu | Export FAB or prominent toolbar button |
| Google Export | File menu | Same export sheet, second option |
| Validation | Toolbar (2 buttons) | Inline status with tap-to-detail |

---

### CF3 — Chapter Navigation Is Not Connected to the Editor
**Severity:** CRITICAL
**File:** `src/ui/EditorWindowController.swift:367-375, 479-486`

The chapter sidebar (`NSTableView`) shows chapters, but:
1. Selecting a chapter in the table does NOT navigate to it in the text view
2. "Insert Chapter Break" (`insertChapter()`) inserts literal text `"--- Chapter Break ---"` into the `NSTextView`, but does NOT create a new `Chapter` in `document.chapters`
3. Tapping "Add Chapter" creates a chapter in the data model but doesn't scroll the editor to it

**Result:** The chapter list and the editor text are in two separate, disconnected states. The author's fundamental workflow — organizing chapters and jumping between them — is broken.

**Required fix for iOS:**
- Each chapter gets its own `UITextView` (or SwiftUI `TextEditor`)
- Selecting a chapter in the sidebar navigates to that chapter's content
- "Insert Chapter Break" creates a new chapter in the model and opens it for editing
- Chapter content is saved back to the model on every edit (live sync)

---

### CF4 — Save/Export Flow Doesn't Match iOS Mental Model
**Severity:** CRITICAL
**Files:** `EbookConverterApp.swift:295-368, 379-501`

**macOS save flow:** Manual save → NSSavePanel → write to disk → NSAlert "Document Saved"
**iOS mental model:** Automatic saving (iCloud/local), no "save" action required
**iOS export flow:** Tap "Share" → `UIActivityViewController` → AirDrop/Files/Email

The current flow requires the user to:
1. Manually save (Cmd+S)
2. Then separately export (Cmd+K / Cmd+G)
3. Then choose a file location

On iOS, this should be:
1. Auto-save happens continuously (as the user types)
2. "Export" opens a share sheet with KDP HTML and EPUB options
3. User sends to Files, AirDrop, or email directly

---

## HIGH FLOW ISSUES

### HF1 — Statistics Are on Demand, Not Ambient
**File:** `src/ui/EditorWindowController.swift:613-639`

Calling `toggleStatistics()` shows an `NSAlert` with word count. The sidebar labels exist but never update (only called on `addChapter()`).

**Authors love live stats.** Word count per chapter, daily goal tracking, estimated reading time — these should be permanently visible at the bottom of the screen, updating as the user types.

**Required:** Always-visible stats bar (word count, chapter count, reading time). Consider a session word count ("Today: +1,240 words") for motivation.

---

### HF2 — TTS Playback Has No Visual Feedback
**File:** `src/ui/EditorWindowController.swift:574-589`

When the user taps "Play", a `TextToSpeech` starts speaking, then an `NSAlert` appears saying "Text-to-speech playback has started." The alert blocks the UI. There's no word highlighting, no progress bar, no elapsed time display.

**For iOS, TTS should work like Apple Books:**
- Text highlighting moves with the spoken word (`speechProgress` delegate is already implemented in TextToSpeech.swift — just needs to be connected)
- Mini-player at bottom with play/pause/speed controls
- No blocking modal

---

### HF3 — No Chapter Reordering on iOS
**File:** `src/models/EbookDocument.swift:108-114`

`EbookDocument.moveChapter()` exists but no UI exposes it. On macOS, the NSTableView could support drag-and-drop reordering (but it's not implemented). On iOS, this is critical.

**Required:** `UITableView` with `moveRow(at:to:)` enabled, or SwiftUI `List` with `.onMove` modifier. Chapter reordering is a core authoring workflow.

---

### HF4 — No Chapter Deletion UI
**File:** `src/models/EbookDocument.swift:103-106`

`EbookDocument.removeChapter()` exists but no UI calls it. There's no way for the user to delete a chapter.

**Fix:** iOS swipe-to-delete on the chapter list, with a confirmation alert.

---

### HF5 — Theme System Is Underutilized
**File:** `src/ui/ColorThemeManager.swift:227-257`

`recommendThemeForWritingType()` and `getThemeForTimeOfDay()` are implemented but never called. The app has a genuinely interesting feature — automatic theme recommendations based on genre and time of day — that no user will ever discover.

**Fix for iOS:**
1. During onboarding: "What are you writing?" → auto-set theme
2. Theme selector shows genre + time-of-day recommendation badge
3. Optional: prompt to switch themes at different times of day

---

## MEDIUM FLOW ISSUES

### MF1 — Book Metadata Has No UI
**File:** `src/models/EbookDocument.swift:15-36`

`BookMetadata` has title, author, description, ISBN, publisher, publication date, genre, language, rights, subject. The user can set none of these — there's no metadata editing UI. But both KDP and Google validators check for title and author.

**Fix:** "Book Settings" sheet (title, author, description, ISBN), accessible from navigation bar or settings. Required before export.

---

### MF2 — Validation Results Are Non-Actionable
**File:** `src/ui/EditorWindowController.swift:556-572`

Validation shows an `NSAlert` with a list of error strings. There's no way to tap an error and jump to the problem location, no in-editor highlighting of problematic text, no inline suggestions.

**Fix:** Validation results as a side panel or sheet with tappable issues that highlight the relevant text.

---

### MF3 — "Insert Footnote" Inserts `[Footnote: ]` as Raw Text
**File:** `src/ui/EditorWindowController.swift:517-528`

Footnotes are critical for non-fiction authors. The current implementation inserts `[Footnote: ]` as literal bracket text. KDP and EPUB both have proper footnote formatting. This is a data fidelity problem.

---

### MF4 — No Image Flow on iOS
**File:** `src/ui/EditorWindowController.swift:488-514`

`insertImage()` uses `NSOpenPanel` — AppKit only. On iOS, image insertion requires `UIImagePickerController` or `PHPickerViewController`. The image resizing logic (line 504-509) uses `NSImage` which is also AppKit-only.

---

## ENGAGEMENT RETENTION ANALYSIS

**What keeps authors coming back:**
- Daily writing streaks (not implemented)
- Word count goals (not implemented)
- Chapter completion status (not implemented)
- Export history ("You exported 3 chapters last week") (not implemented)

**What Avant Garde does well for engagement:**
- 12 themes for mood-matched writing environment (great feature, poor discovery)
- TTS proofing encourages review passes (good workflow, poor UX)
- Dual-platform export is a genuine time-saver (core differentiator)

**Recommendation:** For iOS v1.0, focus on the core loop (Write → TTS Review → Export). Writing streak and goal features can be v1.1.

---

## FEATURE PRIORITY FOR iOS v1.0

| Feature | Status | Priority |
|---------|--------|----------|
| Write text in chapters | Broken (disconnected model) | P0 |
| Navigate between chapters | Broken (no selection handler) | P0 |
| Auto-save document | Missing | P0 |
| Export to KDP HTML | Works (core logic) | P0 |
| Export to Google EPUB | Works (core logic) | P0 |
| Choose writing theme | Works (UI buried) | P1 |
| TTS chapter playback | Works (poor UX) | P1 |
| Book metadata entry | Missing (no UI) | P1 |
| Chapter reordering | Logic exists, no UI | P1 |
| Chapter deletion | Logic exists, no UI | P1 |
| Validation results with jump-to | Works (poor UX) | P2 |
| Onboarding | Missing | P1 |
| Word count stats (live) | Broken (never updates) | P1 |
| Daily writing goals | Missing | P2 (v1.1) |
| Writing streaks | Missing | P2 (v1.1) |
| Footnote proper formatting | Stub | P2 |
| Image insertion (iOS) | Broken (AppKit) | P2 |
