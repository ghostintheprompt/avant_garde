# PRODUCTION CODE AUDIT — Avant Garde v2.0
## Code Quality & Technical Debt Analysis
**Date:** February 2026
**Score: 8/10** (up from 5.5/10)

---

## Executive Summary

The codebase is in substantially better shape. All 6 `print()` statements are gone, the duplicate `ValidationSeverity` enum is resolved, `NSDocument` inheritance is removed, and the async anti-patterns are fixed. The main remaining technical debt is a cluster of dead code (4 files with no callers in the new SwiftUI layer), the reference-type observation problem in `DocumentViewModel`, and three iOS version compatibility issues.

---

## Code Quality Wins (v2.0 vs v1.0)

| Issue | v1.0 | v2.0 |
|-------|------|------|
| `print()` statements | 6 | **0** ✓ |
| TODOs in user-visible paths | 4 | **0** ✓ |
| Duplicate `ValidationSeverity` | Yes | **No** ✓ |
| Duplicate `escapeHTML()` | Yes | **No** ✓ (HTMLEscaping.swift) |
| `Thread.sleep` in production | Yes | **No** ✓ |
| `NSDocument` inheritance | Yes | **No** ✓ |
| AppKit imports in core models | Yes | **No** ✓ |
| `@main` conflict | Yes | **No** ✓ |

---

## Dead Code — 4 Files With No Active Callers

### D1 — `src/audio/VoiceManager.swift` (165 lines)
`VoiceManager.shared` is never called from any view or viewmodel. `DocumentViewModel` accesses voices via `audioController.getAvailableVoices()` which delegates to `TextToSpeech.availableVoices` directly. `VoiceManager` is an orphaned singleton.

**Recommendation:** Delete the file. The functionality it provides (voice categories, quality comparison strings, installation instructions) can be added back as needed when the UI uses it.

### D2 — `src/editor/FormattingEngine.swift` (128 lines — partially dead)
`validateForPlatform(_:text:)` and `convertFormatting(from:to:text:)` are never called from `DocumentViewModel` or any view. The `ValidationSeverity` / `ValidationError` types defined here ARE used (by `GoogleConverter` and `ExportValidator`), so the file can't be deleted wholesale.

**Recommendation:** Delete the `FormattingEngine` class itself and keep only the type definitions. Or move the type definitions to a shared `ValidationTypes.swift` and delete the whole file.

### D3 — `src/models/ConversionSettings.swift` (10 lines)
`ConversionSettings` is instantiated nowhere in the new codebase. It was used by the old `EditorWindowController` which is deleted.

**Recommendation:** Delete the file.

### D4 — `src/parsers/EbookParser.swift` + `src/parsers/FormatDetector.swift`
Both are registered in `ServiceContainer` but never resolved in `DocumentViewModel`. The `EbookParser.parse(filePath:)` returns a hardcoded placeholder string: `"Parsed content from \(filePath)"` — it was never implemented.

**Recommendation:** Keep `FormatDetector` — it will be needed when implementing the "Open..." import flow (reading existing EPUB/MOBI files). Delete or stub `EbookParser`.

---

## Architecture Issues

### A1 — `EbookDocument` Is a Class with SwiftUI `@Published`
**File:** `src/viewmodels/DocumentViewModel.swift:22`
**Issue:** Using a reference type as an `@Published` property in an `ObservableObject` is a well-known SwiftUI pitfall. Property mutations don't fire the publisher, so views don't re-render. This affects:
- Chapter list word count display
- Status bar live word count
- Any view that reads `document.chapters` or `document.metadata`

**This is the root cause of multiple bugs** (BUG_HUNT B5, B6). The recommended fix is one of:

**Option A (minimal):** Add `objectWillChange.send()` before every mutation in `DocumentViewModel`:
```swift
func updateChapterContent(_ content: String, for id: UUID) {
    objectWillChange.send()
    guard let index = ... else { return }
    document.chapters[index].content = content
    ...
}
```

**Option B (architectural):** Convert `EbookDocument` to a struct. This is cleaner but requires auditing all mutation sites (converters receive it by value already, which is actually correct behavior — they take a snapshot). `EbookDocument` is currently passed to `KDPConverter.convertToKDP(document:)` by reference; converting to struct means changes inside the converter won't affect the caller's copy, which is the desired behavior.

### A2 — `DocumentViewModel` Is `@MainActor` But File I/O Is Synchronous
**File:** `src/viewmodels/DocumentViewModel.swift:128-140`
**Issue:** `save()` calls `fileManager.save(document, to: url)` which is synchronous. On `@MainActor`, this blocks the main thread during file write. For a 500KB document this is ~10-50ms — borderline acceptable but will cause dropped frames on older devices.

**Fix:** Make `DocumentFileManager.save()` async:
```swift
func save(_ document: EbookDocument, to url: URL) async throws {
    let data = try document.toData()
    try await Task.detached { try data.write(to: url, options: .atomic) }.value
}
```

### A3 — `ServiceContainer` Registers `AudioController` as Factory But Intent Is Singleton
**File:** `src/utils/ServiceContainer.swift:107`
```swift
registerFactory(AudioController.self) { AudioController() }
```
`DocumentViewModel` calls `ServiceContainer.shared.audioController` once and stores it. But `ServiceContainer`'s convenience property creates a new instance each time:
```swift
var audioController: AudioController {
    return resolve(AudioController.self) ?? AudioController()
}
```
Any secondary caller gets a different `AudioController` with no TTS delegate set. Should be `registerLazySingleton`.

---

## iOS Compatibility Issues

### IC1 — Three APIs Require iOS 17, Deployment Target Is iOS 16
| API | File | Line |
|-----|------|------|
| `onChange(of:)` 2-param closure | ChapterEditorView.swift | 78, 86 |
| `ContentUnavailableView` | ValidationResultsView.swift | 98 |
| `.symbolEffect(.variableColor)` | ContentView.swift | 111 |

All three require `#available(iOS 17, *)` guards or replacement implementations. These are compile/runtime errors on iOS 16.

---

## Positive Code Quality Observations

- `Logger.swift` is used consistently throughout — no `print()` anywhere in production code
- `HTMLEscaping.swift` properly consolidates the duplicate extension
- `DocumentFileManager` cleanly separates file I/O from the ViewModel
- `ExportValidator` returns pure data structs — no UI dependencies
- `AVAudioSession` is properly guarded with `#if os(iOS)`
- `AppKit` import in `FormattingEngine` is properly guarded with `#if canImport(AppKit)`
- `KDPConverter` and `GoogleConverter` correctly use `Task.detached` and local `var formatting` copies
- All `@ObservableObject` delegate callbacks use `nonisolated` + `Task { @MainActor in }` pattern correctly

---

## Technical Debt Inventory

| Debt Item | Effort | Priority |
|-----------|--------|----------|
| Dead code: VoiceManager, ConversionSettings | 30 min | High |
| Dead code: EbookParser, FormattingEngine class | 30 min | Medium |
| objectWillChange.send() on all mutations | 1 hour | Critical |
| onChange two-param iOS 16 fix | 15 min | Critical |
| ContentUnavailableView iOS 16 fix | 30 min | Critical |
| symbolEffect iOS 16 fix | 5 min | Critical |
| AudioController → lazy singleton | 10 min | Medium |
| Async file I/O in DocumentViewModel | 1 hour | Medium |
| Auto-save recovery on relaunch | 2 hours | High |

---

## Launch Readiness Verdict

**Not yet ready for App Store** due to iOS 16 compatibility issues (build errors/crashes). Once those 3 items are fixed (~1 hour of work), the code quality meets App Store standards. The dead code and architectural improvements are important but not blocking.

**Code Quality Score: 8/10**
- 10/10 for elimination of previous critical issues
- 7/10 for architecture (reference-type ObservableObject problem)
- 9/10 for consistency and patterns
- 6/10 for dead code hygiene
