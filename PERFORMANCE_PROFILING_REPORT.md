# AUDIT 3: Performance Profiling — iOS Mobile
## Avant Garde Authoring App

**Date:** February 2026
**Target:** iPhone SE (minimum) → iPhone 16 Pro Max (maximum), iPad (all sizes)
**Targets:** <500ms to first editor, smooth 60fps typing, <1s export for average book

---

## EXECUTIVE SUMMARY

**Score: 6/10 (for macOS) / 3/10 (for iOS readiness)**

The core business logic (converters, parsers, TTS engine) performs well. The async/await pattern for exports is correct. However, there are several architectural issues that will cause measurable iOS performance problems: synchronous text processing on the main thread, a potential deadlock in the ServiceContainer, redundant async wrapping that defeats the purpose of async/await, no lazy chapter loading, and an AVAudioSession configuration missing for iOS.

---

## CRITICAL PERFORMANCE ISSUES

### P1 — ServiceContainer Deadlock Risk Under Load
**File:** `src/utils/ServiceContainer.swift:55-69`
**Severity:** CRITICAL
**Impact:** App freeze / watchdog kill on iOS

The `registerLazySingleton` factory closure captures `self.lock` and attempts to re-acquire it:

```swift
func registerLazySingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
    lock.lock()          // ← Lock acquired here
    defer { lock.unlock() }

    factories[key] = {
        let instance = factory()
        self.lock.lock()  // ← DEADLOCK: trying to acquire same lock while it's held
        self.singletons[key] = instance
        self.factories.removeValue(forKey: key)
        self.lock.unlock()
        return instance
    }
}
```

`NSLock` is not reentrant. If the factory closure is called while `registerLazySingleton` still holds the lock (which can happen if `resolve()` is called from within a factory initialization chain), the app will deadlock.

**Fix:** Use `NSRecursiveLock` instead of `NSLock`, or restructure to avoid nested locking. The simplest fix: promote the singleton promotion to happen outside the lock or use an `os_unfair_lock` with proper recursive checking.

---

### P2 — `withCheckedThrowingContinuation` + Inner `Task` Is Redundant and Risk-Prone
**Files:** `src/converters/KDPConverter.swift:14-26`, `src/converters/GoogleConverter.swift:14-26`
**Severity:** HIGH
**Impact:** Thread overhead, subtle cancellation bugs

```swift
func convertToKDP(document: EbookDocument) async throws -> Data {
    return try await withCheckedThrowingContinuation { continuation in
        Task {                              // ← Creates new Task
            do {
                let data = try convertToKDPSync(document: document)
                continuation.resume(returning: data)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
```

Problems:
1. `withCheckedThrowingContinuation` + inner `Task` is unnecessarily complex. The caller already awaits, so just `Task.detached` or direct async would work.
2. If the outer task is cancelled, the inner `Task` continues running (no cancellation propagation). On iOS, the system aggressively cancels tasks when the app backgrounds.
3. Thread hop: creates a continuation on one thread, resumes on another.

**Fix:** Simplify to direct async:
```swift
func convertToKDP(document: EbookDocument) async throws -> Data {
    return try await Task.detached(priority: .userInitiated) {
        try self.convertToKDPSync(document: document)
    }.value
}
```
Or better, mark `convertToKDPSync` as `nonisolated` and call it directly in an async context.

---

### P3 — FormattingEngine Text Enumeration Runs on Main Thread
**File:** `src/editor/FormattingEngine.swift:123-133`
**Severity:** HIGH
**Impact:** UI freeze on long books during validation

```swift
text.enumerateAttribute(.font, in: NSRange(location: 0, length: text.length)) { (font, range, _) in
    if let nsFont = font as? NSFont {
        // Check each font in the entire document
    }
}
```

For a 100,000-word novel, this enumeration runs through thousands of attribute ranges. This runs synchronously wherever `validateForPlatform()` is called, which is on the main thread (triggered by toolbar button action).

**Impact on iOS:** iOS is more strict about main thread responsiveness. A 200ms+ main thread block during validation will trigger the watchdog at 250ms and cause dropped frames or app termination on older devices.

**Fix:** Move `validateForPlatform()` calls to a `Task { await MainActor.run { ... } }` pattern that performs the computation off-main and returns to main for UI updates.

---

### P4 — No AVAudioSession Configuration for iOS
**File:** `src/audio/TextToSpeech.swift:40-46`
**Severity:** HIGH
**Impact:** TTS silent or interrupted by other apps on iOS

On macOS, `AVSpeechSynthesizer` works without explicit audio session configuration. On iOS, without setting up `AVAudioSession`, the synthesizer will:
- Be silenced when the phone is on silent mode (expected behavior, but needs testing)
- Compete with music/podcasts incorrectly (no category set)
- Not resume after interruptions (phone call, Siri)

**Required iOS-only setup:**
```swift
#if os(iOS)
try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
try AVAudioSession.sharedInstance().setActive(true)
#endif
```

Also: implement `AVAudioSessionInterruptionNotification` observer to pause/resume TTS when interrupted by calls.

---

## HIGH PERFORMANCE ISSUES

### P5 — ServiceContainer Factory Creates New TextToSpeech on Every Resolve
**File:** `src/utils/ServiceContainer.swift:151-157`
**Severity:** HIGH

`TextToSpeech` is registered as a **factory** (new instance each time), but `AVSpeechSynthesizer` is expensive to initialize and should be a singleton. Creating a new `AVSpeechSynthesizer` each time `ServiceContainer.shared.resolve(TextToSpeech.self)` is called wastes memory and potentially causes "audio glitch" as the old synthesizer is deallocated mid-speech.

**Found in code:**
- `EbookConverterApp.swift:532-534`: Creates `TextToSpeech()` directly (bypassing ServiceContainer)
- `EditorWindowController.swift:580`: Uses `ServiceContainer.shared.textToSpeech` (gets new factory instance)
- Two separate `TextToSpeech` instances → two separate `AVSpeechSynthesizer` → potential conflicts

**Fix:** Change `TextToSpeech` registration from `registerFactory` to `registerLazySingleton`.

---

### P6 — All Chapters Loaded Into Memory at Once
**File:** `src/models/EbookDocument.swift:56-60, 84-90`
**Severity:** MEDIUM-HIGH

The entire `EbookDocument` (all chapters, all content) is loaded into memory when a document is opened. For a 100,000-word novel, this is ~600KB-2MB of plain text — acceptable. But if the document contains embedded images (planned feature), this could reach 50-100MB, which iOS will aggressively evict under memory pressure.

**Current behavior:** `read(from:)` decodes all chapters at once into memory.
**Required for iOS:** Lazy chapter loading — load chapter content on demand as user navigates to it, not all at once.

---

### P7 — Simulated `Thread.sleep` in Production Conversion Methods
**Files:** `src/converters/KDPConverter.swift:319-322`, `src/converters/GoogleConverter.swift:419-422`
**Severity:** HIGH

```swift
func convert(from source: EbookFormat, completion: @escaping (Bool) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        Thread.sleep(forTimeInterval: 0.5)  // ← Simulated delay in production
        completion(true)
    }
}
```

These `Thread.sleep` calls in `Converter.convert()` protocol implementations artificially delay every conversion by 500ms. This method is called for every conversion. On iOS, blocking a thread with `Thread.sleep` wastes a thread from the limited thread pool and adds unnecessary latency.

**Fix:** Remove `Thread.sleep`. If a progress indicator is needed, simulate it with a proper `Timer` or progress reporting via `AsyncSequence`.

---

## MEDIUM PERFORMANCE ISSUES

### P8 — `getWordCount()` Re-Splits All Chapter Content on Every Call
**File:** `src/models/EbookDocument.swift:168-175`
**Severity:** MEDIUM

```swift
func getWordCount() -> Int {
    return chapters.reduce(0) { total, chapter in
        let words = chapter.content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return total + words.count
    }
}
```

Every call to `getWordCount()` performs a full string split on all chapter content. If this is called frequently (live word count updates on every keystroke), and the document has 50+ chapters, this compounds quickly.

**Fix:** Cache word count per chapter, invalidate cache only when that chapter's content changes. Or use `NSRegularExpression` word boundary counting which is faster for large strings.

---

### P9 — NSRegularExpression in `parseKDPChapters` and `parseGoogleChapters` Not Compiled
**Files:** `src/converters/KDPConverter.swift:210-211`, `src/converters/GoogleConverter.swift:276`
**Severity:** MEDIUM

```swift
let regex = try? NSRegularExpression(pattern: chapterPattern, options: .dotMatchesLineSeparators)
```

`NSRegularExpression` is compiled from the pattern string each time this function runs. For parsing large documents, this adds unnecessary overhead.

**Fix:** Compile regex patterns at class initialization time as static properties:
```swift
private static let chapterRegex = try? NSRegularExpression(pattern: chapterPattern, options: .dotMatchesLineSeparators)
```

---

### P10 — `DateFormatter` Created Inside Computed Property (Called Repeatedly)
**File:** `src/models/EbookDocument.swift:33-36`
**Severity:** MEDIUM

```swift
var publicationDate: String {
    let formatter = DateFormatter()  // ← Expensive to create
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: publishDate)
}
```

`DateFormatter` is one of the most expensive objects to create in Foundation. This computed property creates a new one every time it's accessed (called during every KDP/Google export).

**Fix:**
```swift
private static let publicationDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

var publicationDate: String {
    return BookMetadata.publicationDateFormatter.string(from: publishDate)
}
```

---

## PERFORMANCE TARGETS FOR IOS

| Metric | Target | Estimated Current |
|--------|--------|-------------------|
| App launch to first editor | < 500ms | ~300ms (macOS, likely similar on iOS) |
| Document open (avg novel) | < 1s | ~200ms |
| KDP export (avg novel) | < 2s | ~1s + 500ms sleep = 1.5s |
| Validation (full document) | < 300ms | Unknown (synchronous) |
| Word count update (keystroke) | < 16ms (1 frame) | ~5-50ms depending on doc size |
| TTS start | < 200ms | ~100ms |
| Theme switch | < 100ms | 0ms (notification posted, never applied) |
| Memory footprint (avg novel) | < 50MB | ~20MB text + overhead |

---

## BATTERY AND THERMAL CONSIDERATIONS

**TTS (AVSpeechSynthesizer):** Moderate CPU usage. For a 100-page chapter (30-40 min TTS), this is significant. Acceptable but should test thermal performance on iPhone 12 mini (thermally constrained).

**Export:** Single-threaded synchronous work inside async wrapper. Export of a 500-page book could run for 3-5 seconds on an older iPhone. Consider chunking the export with progress updates.

**Typing:** `UITextView` with `NSAttributedString` for rich text is well-optimized by Apple. No custom performance work needed here unless adding custom syntax highlighting.
