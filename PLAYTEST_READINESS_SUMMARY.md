# PLAYTEST READINESS SUMMARY
## Avant Garde — Professional Ebook Authoring App
### Pre-Launch Engineering Audit Executive Summary

**Date:** February 2026
**Auditor:** Claude Code (Sierra-Quality Standards)
**App:** Avant Garde — ebook authoring and export tool for KDP + Google Play Books
**Codebase:** ~7,873 lines Swift, macOS 13.0+, AppKit, SPM

---

## AUDIT SCORES AT A GLANCE

| Audit | Score | Verdict |
|-------|-------|---------|
| UI/UX Polish (iPhone + iPad) | 2/10 | AppKit-only — iOS requires complete rewrite |
| App Engagement & User Flow | 5/10 | Core loop is broken; key features invisible |
| Performance (iOS Mobile) | 3/10 | Deadlock, blocking main thread, no audio session |
| Crash & Bug Hunt | 4/10 | Data loss bug, 3 critical crashes, 4 silent failures |
| Production Code Quality | 5.5/10 | Good architecture, real technical debt |
| **Overall iOS Readiness** | **2/10** | **Not shippable for iOS without major work** |

---

## THE ONE THING YOU NEED TO KNOW

**Avant Garde runs on macOS only.** Every UI class in the codebase — `NSWindow`, `NSViewController`, `NSSplitView`, `NSTableView`, `NSTextView`, `NSAlert`, `NSColor`, `NSFont`, `NSDocument` — is AppKit-exclusive. The app cannot compile for iOS in its current form.

**The good news:** The core business logic is solid and largely portable:
- KDP and Google converters (need minor cleanup)
- TTS audio engine (needs AVAudioSession setup for iOS)
- Document model (needs to drop NSDocument inheritance)
- Service container (needs NSLock → NSRecursiveLock fix)
- Logger, error recovery, validation logic

**The work:** UI layer needs to be rewritten in SwiftUI (recommended) or UIKit. This is substantial but the foundation doesn't need to be discarded — only the presentation layer.

---

## TOP 10 CRITICAL ISSUES (Ranked by Priority)

### #1 — App is AppKit-only; iOS target missing entirely
**Severity:** CRITICAL | **Files:** Package.swift, all src/ui/*, EbookDocument.swift, ColorThemeManager.swift, FormattingEngine.swift
The entire app needs an iOS-compatible UI layer. Nothing in `src/ui/` will compile for iOS.
**Fix:** Rewrite UI in SwiftUI (cross-platform) or UIKit. Adapt models and engines.

---

### #2 — Text editor content is NEVER saved back to the document model
**Severity:** CRITICAL | **File:** EditorWindowController.swift
The NSTextView/UITextView content is never written to `document.chapters[n].content`. Every save exports empty chapters. This is a **data loss bug**.
**Fix:** `NSTextViewDelegate.textDidChange` → sync text to `document.chapters[currentIndex].content`

---

### #3 — `makeWindowControllers()` crashes when "Main" storyboard is missing
**Severity:** CRITICAL | **File:** EbookDocument.swift:66
Crashes when any saved document is re-opened. The storyboard doesn't exist — UI is programmatic.
**Fix:** Delete the `makeWindowControllers()` override entirely.

---

### #4 — ServiceContainer deadlock under nested initialization
**Severity:** CRITICAL | **File:** ServiceContainer.swift:55-69
`NSLock` is non-reentrant. Lazy singleton factory tries to re-acquire the same lock. App freeze.
**Fix:** Replace `NSLock` with `NSRecursiveLock`.

---

### #5 — `ValidationSeverity` enum defined twice — compile error
**Severity:** CRITICAL | **Files:** FormattingEngine.swift:16, GoogleConverter.swift:484
Duplicate type definition. Will cause compile failure when modules share scope.
**Fix:** Define once in Models target, import everywhere.

---

### #6 — Chapter table view has no data source — always empty
**Severity:** HIGH | **File:** EditorWindowController.swift:79-88
`NSTableView` never has `.dataSource` or `.delegate` set. Chapter list always shows blank.
**Fix:** Implement `NSTableViewDataSource` + `NSTableViewDelegate`, or replace with SwiftUI `List`.

---

### #7 — Themes are applied but editor never observes theme changes
**Severity:** HIGH | **File:** ColorThemeManager.swift:196-207, EditorWindowController.swift
`.themeDidChange` notification is posted but never observed. Themes appear to do nothing.
**Fix:** Add `NotificationCenter.addObserver` in editor controller; update text view colors.

---

### #8 — Word count, reading time stats never update while typing
**Severity:** HIGH | **File:** EditorWindowController.swift:643-655
`updateStatistics()` only called in `addChapter()`. Sidebar always shows "Words: 0".
**Fix:** Implement `textDidChange` delegate; sync text to model; call `updateStatistics()`.

---

### #9 — `exportToEPUB()` returns plain text, not a valid EPUB ZIP archive
**Severity:** HIGH | **File:** EbookDocument.swift:137-149
EPUB files are ZIP archives with XML manifests. The current implementation returns raw concatenated text. This file is rejected by every EPUB reader and every publishing platform.
**Fix:** Implement proper EPUB 3.0 structure with OPF package, NCX navigation, and XHTML chapters in a ZIP archive. (ZipFoundation or Foundation's `Process` can handle zipping.)

---

### #10 — 4 user-visible menu actions that silently do nothing
**Severity:** HIGH | **File:** EbookConverterApp.swift:537,569,573,630
"Play Current Chapter" always plays chapter 1. "Voice Settings" doesn't open voice tab. "Help" prints to console. "Report Issue" prints to console.
**Fix:** Implement each TODO before shipping.

---

## ISSUE COUNT SUMMARY

| Severity | UI/UX | Engagement | Performance | Bugs | Code | Total |
|----------|-------|------------|-------------|------|------|-------|
| Critical | 6 | 4 | 2 | 3 | 2 | **17** |
| High | 5 | 5 | 5 | 8 | 4 | **27** |
| Medium | 5 | 4 | 3 | 3 | 3 | **18** |
| Low | 4 | 2 | 0 | 0 | 2 | **8** |
| **Total** | **20** | **15** | **10** | **14** | **11** | **70** |

---

## WHAT'S ACTUALLY GOOD (Celebrate the Strengths)

- **Service container is professional-grade.** Thread-safe DI with singleton/factory/lazy patterns. Beyond what most iOS apps have.
- **Async/await conversion pipeline is correct.** KDP and Google converters are well-structured.
- **Logger system with os.log categories.** Exactly what Apple recommends. Ready for Instruments.
- **Codable models are clean.** Round-trip serialization will work once the text-sync bug is fixed.
- **HTML escaping in both converters.** Security-conscious. No XSS risk in the exported HTML.
- **Error recovery system is thoughtful.** Structured error handling with user-facing recovery options.
- **TTS engine is feature-complete.** Word-level progress tracking via `AVSpeechSynthesizerDelegate` is already wired — just needs UI to display it.
- **12 writing themes with color psychology.** Genuinely differentiated feature. Just needs to actually apply to the editor.
- **KDP and Google validation logic is solid.** Checks file sizes, metadata completeness, content validity.

---

## MIGRATION PLAN: macOS → iPhone + iPad

### Phase 1: Foundations (Before Any UI Work)
Fix the platform-agnostic code that's broken regardless of iOS/macOS:

1. Fix `ServiceContainer` deadlock (NSLock → NSRecursiveLock) — 1h
2. Delete `makeWindowControllers()` crash — 15min
3. Fix `ValidationSeverity` duplicate enum — 30min
4. Fix reference type mutation in `optimizeDocumentForKDP/Google` — 1h
5. Remove `Thread.sleep` from converter stubs — 30min
6. Consolidate `escapeHTML()` into shared extension — 30min
7. Remove all `print()` statements → Logger calls — 1h

**Phase 1 total: ~5 hours**

---

### Phase 2: Decouple from AppKit (Cross-Platform Models)
Make the model and engine layer compile on iOS:

1. Remove `NSDocument` inheritance from `EbookDocument` — make it a plain class with a `DocumentFileManager` service for I/O — 4h
2. Replace `NSColor` in `ColorThemeManager` with `UIColor`/SwiftUI `Color` using `#if os(macOS)` — 2h
3. Replace `NSFont` in `FormattingEngine` with `UIFont` using `#if os(macOS)` — 2h
4. Add `AVAudioSession` setup in `TextToSpeech.init()` for iOS — 1h
5. Add `.iOS(.v16)` to Package.swift platform targets — 15min

**Phase 2 total: ~10 hours**

---

### Phase 3: Create iOS Xcode Project
The current codebase uses SPM with a command-line executable structure. An iOS app requires an Xcode project with app target, entitlements, Info.plist, and app icons.

1. Create new Xcode project (iOS App, SwiftUI or UIKit)
2. Import SPM packages (Converters, Parsers, Audio, Models, Editor)
3. Configure bundle identifier, signing, capabilities
4. Set up Info.plist (microphone usage, speech recognition descriptions)
5. Add app icons (AppIcon.appiconset exists — verify all required sizes)

**Phase 3 total: ~4 hours**

---

### Phase 4: iPhone UI — Core Editor
The minimum viable iOS editor experience:

1. `ContentView.swift` — root SwiftUI view with chapter list + editor
2. `ChapterListView.swift` — sidebar on iPad, sheet/drawer on iPhone
3. `ChapterEditorView.swift` — SwiftUI `TextEditor` per chapter with TextKit 2 foundation
4. Text→model sync on every keystroke (live)
5. Live word count in navigation bar
6. Keyboard accessory toolbar (Bold/Italic/Undo)
7. "Add Chapter" / swipe-to-delete chapter

**Phase 4 total: ~20 hours**

---

### Phase 5: iPhone UI — Features
Surfaces the existing features in iPhone-accessible UI:

1. Theme picker — navigation bar button with visual grid of 12 themes
2. TTS mini-player — bottom bar with play/pause/speed, word highlighting
3. Export sheet — `UIActivityViewController` with KDP HTML + EPUB options
4. Book metadata form — settings sheet (title, author, description, ISBN)
5. Validation results — sheet with tappable issues

**Phase 5 total: ~15 hours**

---

### Phase 6: iPad Adaptation
Make the iPhone UI scale to iPad properly:

1. `UISplitViewController` / SwiftUI adaptive layout with sidebar
2. Full formatting toolbar on iPad (all 16+ items, icons + labels)
3. iPad popover for theme/voice settings (not full-screen sheet)
4. Keyboard shortcut support (⌘B, ⌘I, ⌘N, ⌘E)
5. Drag-and-drop chapter reordering

**Phase 6 total: ~10 hours**

---

### Phase 7: File Management + iCloud (iOS-specific)
iOS file management is entirely different from macOS:

1. Auto-save to local sandbox (no user "Save" action)
2. Document browser (UIDocumentBrowserViewController) or app-managed library
3. `UIDocumentPickerViewController` for import/export to Files app
4. iCloud Documents sync (optional but expected by users)

**Phase 7 total: ~10 hours**

---

## TOTAL EFFORT ESTIMATE

| Phase | Description | Hours |
|-------|-------------|-------|
| Phase 1 | Fix platform-agnostic bugs | 5h |
| Phase 2 | Decouple from AppKit | 10h |
| Phase 3 | Xcode iOS project setup | 4h |
| Phase 4 | iPhone core editor | 20h |
| Phase 5 | iPhone feature surfaces | 15h |
| Phase 6 | iPad adaptation | 10h |
| Phase 7 | iOS file management | 10h |
| **Total** | **iOS v1.0** | **~74 hours** |

Buffer for unknowns (add 30%): **~96 hours total**

---

## GO / NO-GO RECOMMENDATION

### macOS App Store: ⛔ NO-GO
Fix critical bugs first:
- B9 (data loss — text not saved to model) — must fix before any user sees this
- B1 (storyboard crash on document open)
- B5 (empty chapter list)
- B7 (themes don't apply)
- 4 silent TODO menu items

Estimated time to macOS playtest-ready: **15-20 hours** of targeted bug fixes

### iOS App Store: ⛔ NOT YET
Full platform port required. The foundation is strong enough to build on — no architectural rebuild needed, just a UI rewrite. The core converters, audio engine, and service infrastructure are worth keeping.

**Realistic path to iOS TestFlight:** 75-100 hours of development
**Realistic path to iOS App Store:** Add 20-30 hours for App Store review preparation, accessibility, screenshots, localizations

---

## CRITICAL FIXES BEFORE PLAYTEST (macOS)

Fix these before sending to any tester:

- [ ] Fix data loss bug: sync text view to document.chapters on every edit
- [ ] Fix storyboard crash: delete makeWindowControllers()
- [ ] Fix chapter list: add NSTableViewDataSource/Delegate
- [ ] Fix themes: observe themeDidChange notification in editor
- [ ] Fix word count: update statistics on textDidChange
- [ ] Fix TTS: track current chapter selection properly
- [ ] Implement Help window (even if minimal)
- [ ] Implement Report Issue (open URL or mail composer)

---

## RED FLAGS IN THIS CODEBASE

- **Data loss bug (B9) is the most serious issue.** Any tester who writes content and reopens the document will lose everything. Fix this before anyone external sees the app.
- **The app has demo-ware patterns.** `loadDemoContent()` prints a marketing pitch to the console. The converter stubs have `Thread.sleep`. The storyboard reference is dead code. These suggest rapid prototyping that needs a cleanup pass.
- **The best features are invisible.** 12 themes, TTS proofing, dual-platform export — these are genuinely differentiated. But none of them surface themselves on iOS. The iOS rewrite is an opportunity to put these front and center.

---

## SUCCESS METRICS FOR iOS LAUNCH

- [ ] User can write a chapter and export it to KDP HTML without data loss
- [ ] User can export to Google EPUB and the file opens in Apple Books
- [ ] All 12 themes visually apply to the editor
- [ ] TTS reads the current chapter with play/pause/speed controls
- [ ] App works on iPhone SE (375pt) through iPhone 16 Pro Max (430pt)
- [ ] App works on all iPad sizes with appropriate split view
- [ ] No crashes in 30-minute writing session
- [ ] Auto-save: reopening app shows exactly what user had written
- [ ] Export to Files app works via share sheet
- [ ] Passes App Store review (privacy, entitlements, screenshots)

**When all checkboxes are checked: ship it.**

---

*Audit completed by Claude Code — February 2026*
*Reports: SIERRA_UI_AUDIT_REPORT.md | APP_ENGAGEMENT_REPORT.md | PERFORMANCE_PROFILING_REPORT.md | BUG_HUNT_REPORT.md | PRODUCTION_CODE_AUDIT.md*
