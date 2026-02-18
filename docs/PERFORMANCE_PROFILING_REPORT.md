# PERFORMANCE PROFILING REPORT — Avant Garde v2.0
## iOS Mobile Performance Analysis
**Date:** February 2026
**Score: 8/10** (up from 3/10)

---

## Executive Summary

The major performance regressions from v1.0 are all fixed: the `NSLock` deadlock is resolved, async conversions use `Task.detached` correctly, `TextToSpeech` is a lazy singleton (not recreated per use), `AVAudioSession` is configured on iOS, and there are no `Thread.sleep` calls. The remaining issues are architectural — `wordCount` re-computation on every render, a `@MainActor` class with synchronous document operations, and auto-save task management that could pile up in edge cases.

---

## Fixed Issues (from v1.0)

| Issue | v1.0 | v2.0 |
|-------|------|------|
| NSLock deadlock in ServiceContainer | ❌ Crash | ✓ NSRecursiveLock |
| withCheckedContinuation + inner Task | ❌ Anti-pattern | ✓ Task.detached |
| Thread.sleep(0.5) in production | ❌ Present | ✓ Removed |
| TextToSpeech as factory (expensive) | ❌ Factory | ✓ Lazy singleton |
| AVAudioSession missing on iOS | ❌ Silent TTS | ✓ Configured |
| FormattingEngine on main thread | N/A | ✓ Not called from UI |

---

## MEDIUM Issues

### M1 — `wordCount` / `characterCount` Recomputed Every Render
**File:** `src/viewmodels/DocumentViewModel.swift:30-34`
**Issue:** `wordCount` is a computed property that iterates all chapters on every call:
```swift
var wordCount: Int { document.getWordCount() }
```
`getWordCount()` splits every chapter's content by whitespace. For a 100,000-word book across 30 chapters, this is thousands of string operations per render tick.

`DocumentViewModel` is `@MainActor` so SwiftUI re-renders can call this frequently. The `StatusBar` subscribes to `viewModel.wordCount` — on every keystroke a `@Published` change fires, SwiftUI re-renders `StatusBar`, which calls `wordCount`, which walks all chapters.

**Fix:** Cache as `@Published`:
```swift
@Published private(set) var wordCount: Int = 0

private func updateStats() {
    wordCount = document.getWordCount()
}
// Call updateStats() in updateChapterContent() and addChapter() / deleteChapter()
```

### M2 — `documentViewModel.document.chapters` Is a Class Property — SwiftUI Doesn't Observe It
**File:** `src/viewmodels/DocumentViewModel.swift:22`
**Issue:** `EbookDocument` is a class (reference type). `@Published var document: EbookDocument` fires when `document` itself is replaced (new assignment), not when its properties mutate. When `updateChapterContent()` mutates `document.chapters[index].content`, SwiftUI views that read `viewModel.document.chapters` won't re-render.

This means:
- `ChapterRow` word counts in the sidebar won't update while typing
- `StatusBar` word count won't update while typing
- Any view reading `viewModel.document.metadata` won't update after `BookSettingsView` saves

**Fix options:**
1. Convert `EbookDocument` to a struct (requires care with converters that take it by value — they already work since we fixed the reference mutation bug)
2. Add `objectWillChange.send()` calls in all mutating methods of `DocumentViewModel`
3. Keep class but manually trigger `@Published` updates via the cached stats approach in M1

Option 2 is the minimal fix:
```swift
func updateChapterContent(_ content: String, for id: UUID) {
    objectWillChange.send()  // add this line
    guard let index = ... else { return }
    ...
}
```

### M3 — Auto-save Task Accumulation Under Rapid Typing
**File:** `src/viewmodels/DocumentViewModel.swift:198-203`
**Issue:** Every call to `markDirty()` cancels the previous `autoSaveTask` and starts a new one. This is correct for debouncing. However, `autoSaveTask` is `Task<Void, Never>` — if the user types continuously for 3+ seconds, the first task completes and writes to disk, then `markDirty()` immediately starts another. This is fine.

The edge case: if `DocumentViewModel` is deallocated while an auto-save task is in flight (e.g., user creates a new document mid-typing), the task holds a `[weak self]` reference and will safely no-op. No issue here.

**Minor:** `DocumentFileManager.autoSave()` is synchronous and uses `Data.write(to:options:atomic)` which is blocking. For large documents, this blocks the calling thread. Since the `Task` runs on the cooperative thread pool (not `@MainActor`), and auto-save is a detached task, the main thread is not blocked. ✓

### M4 — `TextEditor` with Large Content Has No Lazy Loading
**Issue:** `TextEditor` on iOS renders the entire chapter as a single text view. For very long chapters (50,000+ words, ~300KB of text), this can cause noticeable lag during initial render and poor scrolling performance.

**Mitigation:** This is a SwiftUI limitation — `TextEditor` does not have built-in pagination. For v1.0 this is acceptable; document chapters should be capped. In v1.1, consider splitting chapters > 50,000 words with a warning.

---

## LOW Issues

### L1 — `ServiceContainer.audioController` Creates New AudioController Per Access
**File:** `src/utils/ServiceContainer.swift:107`
**Issue:** `AudioController` is registered as a `.registerFactory`, not a singleton. Each call to `ServiceContainer.shared.audioController` creates a new instance. In v2.0, `DocumentViewModel` stores the controller in `self.audioController` from init, so it only creates one — but if any other code calls `ServiceContainer.shared.audioController` it gets a different instance.

**Fix:** Register `AudioController` as `registerLazySingleton` since the app only needs one.

### L2 — `GenerateGoogleEPUB` / `generateKDPHTML` Build Strings via Concatenation
**File:** `src/converters/GoogleConverter.swift:53-60`, `src/converters/KDPConverter.swift`
**Issue:** HTML generation uses repeated `+=` string concatenation on `var content: String`. For a 30-chapter book this means 30+ string reallocations. Each `+=` can copy the entire accumulated string.

**Fix:** Use `[String]` array + `.joined()` or a `StringBuilder` pattern. Minor for typical book sizes but worth fixing for professional quality.

### L3 — `DocumentFileManager.listDocuments()` Has No Async Version
**File:** `src/utils/DocumentFileManager.swift:43-57`
**Issue:** `listDocuments()` is synchronous and calls `FileManager.default.contentsOfDirectory(...)`. For a large library, this blocks the caller. If called from a SwiftUI view's `onAppear`, it blocks the main thread.

**Fix:** Wrap in `Task.detached` when called from UI context.

---

## Performance Baseline (Estimated)

| Metric | v1.0 | v2.0 | Target |
|--------|------|------|--------|
| Cold launch to editor | Crash | ~0.8s | <1s ✓ |
| Chapter switch | Non-functional | <50ms | <100ms ✓ |
| KDP export (10-chapter book) | Stub (0ms) | ~50-100ms | <500ms ✓ |
| TTS start latency | N/A | ~200ms | <500ms ✓ |
| Auto-save write | N/A | ~5-20ms | <100ms ✓ |
| Theme change | Non-functional | <16ms | <16ms ✓ |
