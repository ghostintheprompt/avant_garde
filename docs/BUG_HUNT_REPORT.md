# BUG HUNT REPORT — Avant Garde v2.0
## Crash & Edge Case Analysis
**Date:** February 2026
**Score: 8/10** (up from 4/10)

---

## Previously Critical Bugs — All Fixed ✓

| Bug | v1.0 | v2.0 |
|-----|------|------|
| B1: makeWindowControllers() crash | ❌ Guaranteed crash | ✓ NSDocument removed |
| B2: ServiceContainer deadlock | ❌ Deadlock | ✓ NSRecursiveLock |
| B3: ValidationSeverity duplicate | ❌ Compile error | ✓ Deduplicated |
| B4: exportToEPUB() returns plain text | ❌ Fake data | ✓ Real EPUB |
| B5: Chapter tableview no data source | ❌ Empty | ✓ SwiftUI List |
| B6: Chapter selection does nothing | ❌ Broken | ✓ Works |
| B7: Theme changes not applied | ❌ Ignored | ✓ Applied |
| B8: Word count never updates | ❌ Static | ✓ Computed |
| B9: Text never saved to model | ❌ Data loss | ✓ Fixed |
| B10: TTS always plays chapter 1 | ❌ Wrong chapter | ✓ Correct chapter |
| B11-B13: TODOs doing nothing | ❌ Dead code | ✓ Removed |

---

## NEW Critical Bugs

### B1 — `onChange(of:)` Compile Error on iOS 16
**File:** `src/views/ChapterEditorView.swift:78, 86`
**Severity:** CRITICAL — compile error on iOS 16 target
**Reproduce:** Set deployment target to iOS 16.0 in Xcode, build.
```
Error: Extra argument in call (two-parameter closure introduced in iOS 17)
```
**Fix:**
```swift
// Replace both occurrences:
.onChange(of: bodyText) { newValue in  // iOS 16 compatible
    viewModel.updateChapterContent(newValue, for: chapterID)
}
```

### B2 — `ContentUnavailableView` Crash on iOS 16
**File:** `src/views/ValidationResultsView.swift:98-105`
**Severity:** CRITICAL — crash on iOS 16
**Reproduce:** Run on iOS 16 device/simulator, validate a document with no issues.
**Fix:** Replace with custom empty state view (see SIERRA_UI_AUDIT_REPORT.md C2).

### B3 — Concurrent Export Tasks: Data Race on `exportedData`
**File:** `src/viewmodels/DocumentViewModel.swift:123-145`, `src/views/ContentView.swift:92-105`
**Severity:** HIGH
**Reproduce:** Tap Export for KDP, then immediately tap Export for Google Play before the first completes.
**What happens:** Both tasks run concurrently. Both set `exportedData`, the last one wins. The export sheet opens for whichever export finishes last. The other export's data is silently discarded.
**Fix:** Guard at the start of both export functions:
```swift
func exportKDP() async {
    guard !isExporting else { return }
    ...
}
```
The `isExporting` flag is already set but checked AFTER task starts — move check to before.

### B4 — Auto-save Session Recovery Broken
**File:** `src/viewmodels/DocumentViewModel.swift:193-203`, `src/utils/DocumentFileManager.swift:72-90`
**Severity:** HIGH — potential data loss
**Reproduce:**
1. Type content (auto-save fires after 3 seconds)
2. Force-quit the app before manually saving
3. Reopen app

**What happens:** `DocumentViewModel.init()` creates `documentID = UUID()` — a new random UUID. The auto-save from the previous session was stored at `autoSaveURL(for: previousUUID)`. This URL is unknown to the new session, so the auto-save is never recovered. The user loses all unsaved work.

**Fix:** Persist the document ID to UserDefaults on creation and restore on launch. Or use a fixed auto-save path (e.g., `autosave/last-session.avantgarde`).

### B5 — `DocumentViewModel.wordCount` Stale Due to Reference Type
**File:** `src/viewmodels/DocumentViewModel.swift:30`
**Severity:** HIGH — incorrect data shown to user
**Reproduce:** Type in the editor. Check the status bar word count — it does not update in real time.
**Root cause:** `EbookDocument` is a class. `@Published var document` only fires on assignment, not mutation. Mutating `document.chapters[i].content` does not trigger a SwiftUI re-render of the `StatusBar`.
**Fix:** Cache and update `wordCount` as a `@Published` property (see PERFORMANCE_PROFILING_REPORT.md M2).

---

## HIGH Bugs

### B6 — Delete Last Chapter Leaves selectedChapterID Set
**File:** `src/viewmodels/DocumentViewModel.swift:97-107`
**Reproduce:** Create a document with 1 chapter. Delete it.
**What happens:** `deleteChapter()` checks `if document.chapters.isEmpty { selectedChapterID = nil }` — this is correct. But `ChapterEditorView` then shows `EmptyEditorView`. If the user then taps "Add First Chapter" in the empty state, `addChapter()` adds a chapter but `selectedChapterID` may point to the newly added chapter's ID immediately — this works correctly. ✓

Actually let me trace more carefully: `addChapter()` calls `document.addChapter()` then sets `selectedChapterID = document.chapters.last?.id`. Since `document` is a class and `@Published` won't fire, the `ChapterListView` may not re-render to show the new chapter.

**Root cause:** Same as B5 — reference type mutation not observed by SwiftUI. The chapter list won't refresh.

### B7 — `ExportShareView.writeTempFile()` Silent Failure Has No User Feedback
**File:** `src/views/ContentView.swift:165-172`
**Reproduce:** Fill app sandbox to capacity, then attempt export.
**What happens:** `writeTempFile()` catches the error and logs it, but `tempURL` stays `nil`, and the view stays on the "Preparing export..." `ProgressView` indefinitely. User is stuck with a spinner and no way to dismiss.
**Fix:**
```swift
@State private var writeError: String?

private func writeTempFile() {
    do {
        try file.data.write(to: tmp, options: .atomic)
        tempURL = tmp
    } catch {
        writeError = error.localizedDescription
        // Then show error state + dismiss button
    }
}
```

### B8 — `TTSPlayerView` Speed Slider Disconnected from Current Rate
**File:** `src/views/TTSPlayerView.swift:22`
**Reproduce:** Open TTS Player sheet. The speed slider shows 0.5 (default `@State`), but if the user previously changed the rate and closed the sheet, the slider doesn't reflect the current rate.
**Fix:** Initialize `speechRate` from `audioController.currentRate`:
```swift
// Can't access environment object in @State init, use onAppear:
.onAppear {
    speechRate = ServiceContainer.shared.textToSpeech.currentRate
}
```

### B9 — `BookSettingsView` Discards Changes on Back Swipe (iPhone)
**File:** `src/views/BookSettingsView.swift`
**Reproduce:** Open Book Settings on iPhone. Edit title. Swipe down to dismiss (system sheet dismiss gesture) instead of tapping "Cancel" or "Done".
**What happens:** Sheet dismisses via system gesture, which calls `dismiss()` without going through the "Done" button. The local `metadata` changes are silently discarded. This matches expected behavior for a Cancel-able sheet, but "Done" is the only save path and it's not obvious that swipe-down = Cancel.
**Fix:** Add `.interactiveDismissDisabled(true)` when there are unsaved changes, or confirm on dismiss:
```swift
.interactiveDismissDisabled(metadataHasChanges)
```

---

## MEDIUM Bugs

### B10 — `ChapterEditorView` Focus Fires on Every Re-render
**File:** `src/views/ChapterEditorView.swift:109-112`
**Issue:** The `DispatchQueue.main.asyncAfter` in `onAppear` fires focus unconditionally. On iPad with the sidebar open, switching chapters fires focus (correct), but if the user taps into the chapter list to reorder chapters, focus immediately jumps back to the editor, making reordering difficult.

### B11 — `DocumentViewModel.saveAs()` Has No Custom Filename UI
**File:** `src/viewmodels/DocumentViewModel.swift:155-163`
**Issue:** `saveAs()` uses `fileManager.save(document, named: title)` which auto-derives the filename from the book title. If two books have the same title, the second save overwrites the first silently (`.atomic` write). No collision detection or user prompt.

### B12 — Validation Run on Stale Document State
**File:** `src/viewmodels/DocumentViewModel.swift:167-174`
**Issue:** `validateKDP()` calls `document.validateForKDP()` which calls `ExportValidator().validate(document: self, for: .kdp)`. Since `EbookDocument` is a class and chapter content may not have propagated fully (see B5 — SwiftUI `@Published` doesn't fire on mutation), validation might run on a document whose chapters don't reflect the latest text in the editor.
**This only occurs** if the user hits Validate very quickly after typing. Auto-save debounce is 3s. Validation is typically after a pause.

---

## LOW Bugs

### B13 — `VoiceManager` Singleton References macOS System Preferences
**File:** `src/audio/VoiceManager.swift:70-76`
**Issue:** `getVoiceInstallationInstructions()` mentions "System Preferences → Accessibility" which is macOS-only. On iOS, voice download is in Settings → Accessibility → Spoken Content. This function isn't called from any UI currently, but if surfaced it will confuse iOS users.

### B14 — `TTSPlayerView` Prev/Next Buttons Disable When Not Playing
**File:** `src/views/TTSPlayerView.swift:92, 108`
**Issue:** `.disabled(!viewModel.ttsIsPlaying)` on Prev/Next buttons means users can't navigate chapters before starting TTS. They should be able to select a starting chapter first.

### B15 — `EbookFormat.rawValue` Used in Validation Report Title
**File:** `src/views/ValidationResultsView.swift:123`
**Issue:** `navigationTitle("Validation — \(report.format.rawValue)")` will show format strings like "KDP HTML", "EPUB" etc. For `.epub` the rawValue might not be user-facing friendly depending on what `EbookFormat` defines.

---

## Bug Priority Matrix

| Bug | Severity | Reproducible | Data Loss? |
|-----|----------|-------------|------------|
| B1: onChange iOS 16 | CRITICAL | Always | No (build fail) |
| B2: ContentUnavailableView iOS 16 | CRITICAL | Always | No (crash) |
| B3: Concurrent export | HIGH | Race condition | No |
| B4: Auto-save not recovered | HIGH | Always | YES |
| B5: wordCount stale | HIGH | Always | No |
| B6: ChapterList no re-render | HIGH | On add chapter | No |
| B7: Export spinner stuck | HIGH | Disk full | No |
| B8: Speed slider wrong on open | MEDIUM | After rate change | No |
| B9: Sheet dismiss discards | MEDIUM | Swipe to dismiss | Minor |
