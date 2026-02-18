# APP ENGAGEMENT REPORT — Avant Garde v2.0
## User Flow & Core Loop Analysis
**Date:** February 2026
**Score: 7/10** (up from 5/10)

---

## Executive Summary

The core authoring loop now works end-to-end: chapters are selectable, content persists in the model, TTS reads the correct chapter, themes apply visually, and export generates real data. The critical data-loss bug (B9 from the original audit — text never saved back to model) is fully fixed. The remaining engagement gaps are structural: there is no document library UI, no onboarding, and the path from "just installed" to "exported my first book" has several invisible steps.

---

## Core Loop Assessment

**Current user journey:**
1. Open app → blank Chapter 1 loads ✓
2. Type content → syncs to model via `onChange` ✓
3. Switch chapters → content preserved ✓
4. Apply theme → editor background changes ✓
5. Export → share sheet with real file ✓
6. TTS → reads correct chapter ✓

**Fixed issues from v1.0:**
- ✓ Chapter selection now loads correct content
- ✓ Text changes sync back to `DocumentViewModel`
- ✓ TTS reads selected chapter (not always chapter 1)
- ✓ Theme changes apply to editor background
- ✓ Export generates real KDP HTML and EPUB data
- ✓ Word count is computed from actual model data

---

## CRITICAL Issues

### C1 — No Document Library / File Browser
**Issue:** `DocumentFileManager` saves documents to the app sandbox, but there is no UI to list or open previously saved documents. `DocumentViewModel.load(from:)` accepts a URL, and `ContentView` has a `.fileImporter` trigger, but there is no "Open Recent" or library browser. Users who close the app lose their work unless auto-save happened to fire.

**Impact:** Data loss risk. First-time users returning to the app have no way to find their previous work.

**Fix needed:** A library view — either as a sheet from the toolbar "Open..." button, or as the initial screen before the editor, listing `DocumentFileManager().listDocuments()` sorted by modification date.

### C2 — Auto-save Fires But There's No Recovery on Launch
**File:** `src/viewmodels/DocumentViewModel.swift:188-196`
**Issue:** Auto-save writes to `.autosave/{uuid}.avantgarde` but on app launch, `AvantGardeApp` creates a fresh `DocumentViewModel()` with a new `documentID = UUID()`. The auto-save for the previous session is never checked. The auto-saved file is orphaned and never cleaned up.

**Fix:** On `DocumentViewModel.init()`, check `DocumentFileManager.autoSaveURL(for:)` — but since we don't persist the session UUID, this is broken by design. Auto-save needs to use a stable identifier (e.g., save the last-open file URL to `UserDefaults`).

```swift
// In DocumentViewModel.init():
if let lastURL = UserDefaults.standard.url(forKey: "lastOpenFileURL") {
    load(from: lastURL)
}
```

---

## HIGH Issues

### H1 — No Onboarding for First-Time Users
**Issue:** A first-time user opens the app to a blank Chapter 1 with a cursor. There is no explanation of:
- What Avant Garde is for (KDP / Google Play ebook authoring)
- How to add chapters (the `+` button is subtle)
- Where to set book title/author (hidden in toolbar menu)
- How to export

**Recommended flow:** One-time welcome sheet (3 swipeable cards):
1. "Write your book" → shows chapter list + editor screenshot
2. "Choose a theme" → shows theme grid
3. "Export anywhere" → shows KDP + Google Play logos

Trigger condition: `!UserDefaults.standard.bool(forKey: "onboardingComplete")`

### H2 — "Book Settings" Is Invisible Until User Explores
**File:** `src/views/ContentView.swift:72-78`
**Issue:** Book title, author, and ISBN are critical for export (KDP validation requires both title and author). These are only accessible via the `doc.text` menu → "Book Settings" — a 2-tap navigation path that new users won't discover. All exports will show validation errors on an empty document until discovered.

**Fix:** After creating a new document, show `BookSettingsView` automatically if `metadata.title.isEmpty && metadata.author.isEmpty`.

### H3 — Validation Results Have No "Fix It" Deep Links
**File:** `src/views/ValidationResultsView.swift`
**Issue:** Tapping a validation error (e.g., "Missing required field: title") does nothing. Users must dismiss the sheet, navigate to settings, and find the relevant field themselves.

**Fix:** Make error rows tappable. Errors about metadata (`Missing required field: title/author`) should dismiss the sheet and open `BookSettingsView`. Errors about content should navigate to the relevant chapter.

---

## MEDIUM Issues

### M1 — TTS Player Lacks Chapter Context
**File:** `src/views/TTSPlayerView.swift:56-65`
**Issue:** "Now Playing" only shows when TTS is actively playing. When the user opens the TTS sheet before pressing play, there's no indication of which chapter will be read. A static "Will read: [chapter title]" label when idle would orient users.

### M2 — Export Flow Doesn't Prompt to Validate First
**File:** `src/views/ContentView.swift:92-105`
**Issue:** Users can export directly without validating. KDP will reject uploads with missing metadata. The export menu should suggest validation:
```
Export for KDP
  ↳ Consider validating first (tap to validate)
```
Or simply run validation silently before export and surface blocking errors before generating the file.

### M3 — No Visual Confirmation After Auto-save
**Issue:** Auto-save fires 3 seconds after any change but the status bar only shows "Unsaved" vs "Saved" based on `hasUnsavedChanges`. Since auto-save doesn't set `hasUnsavedChanges = false` (it's not a user-initiated save), the status bar stays "Unsaved" even when a perfectly good auto-save exists.
**Fix:** Auto-save should update a separate `@Published var lastAutoSaveDate: Date?` and show "Auto-saved" with a timestamp.

### M4 — Chapter Reorder Has No Undo
**Issue:** Drag-to-reorder in `ChapterListView` calls `moveChapters(from:to:)` which immediately modifies the model. There's no undo. On a phone with fat-finger touches, accidental reorders are a real risk.
**Fix:** Expose SwiftUI's built-in `UndoManager` via the environment and register chapter moves.

### M5 — No Chapter Duplication
**Issue:** Authors frequently want to duplicate a chapter as a template (especially for recurring structure like chapters with standard headings). Only add and delete are exposed.
**Fix:** Add "Duplicate Chapter" to the swipe actions alongside delete.

---

## LOW Issues

### L1 — Statistics Only Show Totals, Not Per-Chapter Progress
The status bar shows total word count. During writing, authors want to know "how long is THIS chapter?" The per-chapter word count in `ChapterRow` exists in the sidebar but disappears when the sidebar collapses on iPhone.

### L2 — No Reading Goal / Target Word Count
Authors typically write toward a target (80,000 words for a novel). A progress indicator toward a user-set goal would drive engagement.

### L3 — Theme Recommendation Not Surfaced
`ColorThemeManager.recommendTheme(for:)` and `themeForTimeOfDay()` exist but are never called from the UI. These are genuinely useful features that are completely hidden.

---

## Engagement Score by Area

| Area | Before | After |
|------|--------|-------|
| Core write loop | 2/10 | 9/10 |
| Chapter navigation | 3/10 | 9/10 |
| Theme experience | 3/10 | 8/10 |
| TTS experience | 4/10 | 7/10 |
| Export experience | 2/10 | 7/10 |
| Onboarding | 1/10 | 2/10 |
| Document management | 2/10 | 3/10 |
| **Overall** | **5/10** | **7/10** |
