# SIERRA UI AUDIT REPORT — Avant Garde v2.0
## Post-iOS-Port UI/UX Analysis
**Date:** February 2026
**Score: 7.5/10** (up from 2/10 — major improvement)

---

## Executive Summary

The iOS port is architecturally complete and structurally sound. `NavigationSplitView` is correctly implemented, the theme system works cross-platform, and all screens exist. The remaining issues are polish-level: iOS version compatibility guards are missing for three SwiftUI APIs introduced in iOS 17, toolbar placements use deprecated names, and the app lacks a first-launch onboarding state and a document library browser.

---

## CRITICAL Issues (must fix before TestFlight)

### C1 — `onChange(of:)` Two-Parameter Closure: Requires iOS 17
**Files:** `src/views/ChapterEditorView.swift:78`, `:86`
**Issue:** SwiftUI changed `onChange(of:perform:)` signature in iOS 17. The two-parameter closure `{ _, newValue in }` is iOS 17+ only. On iOS 16 this is a compile error.

```swift
// CURRENT (iOS 17+ only):
.onChange(of: bodyText) { _, newValue in
    viewModel.updateChapterContent(newValue, for: chapterID)
}

// FIX — works on iOS 16+:
.onChange(of: bodyText) { newValue in
    viewModel.updateChapterContent(newValue, for: chapterID)
}
```
Same fix needed for `titleText` onChange at line 86.

### C2 — `ContentUnavailableView`: Requires iOS 17
**File:** `src/views/ValidationResultsView.swift:98`
**Issue:** `ContentUnavailableView` is iOS 17+. Will crash on iOS 16.

```swift
// FIX:
VStack(spacing: 12) {
    Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 48))
        .foregroundStyle(.green)
    Text("No Issues")
        .font(.headline)
    Text("Your document passed all checks for \(report.format.rawValue).")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
}
.padding()
```

### C3 — `.symbolEffect(.variableColor)`: Requires iOS 17
**File:** `src/views/ContentView.swift:111`
**Issue:** `.symbolEffect(.variableColor, isActive:)` is iOS 17+ only.

```swift
// FIX — remove the modifier, use a different animation:
Button {
    viewModel.isShowingTTSPlayer = true
} label: {
    Image(systemName: viewModel.ttsIsPlaying ? "waveform" : "headphones")
}
.help("Listen")
// Remove: .symbolEffect(.variableColor, isActive: viewModel.ttsIsPlaying)
```

---

## HIGH Issues

### H1 — Deprecated Toolbar Placement Names
**File:** `src/views/ContentView.swift:71, 85`
**Issue:** `.navigationBarLeading` and `.navigationBarTrailing` are deprecated on iOS 16+ in favor of `.topBarLeading` / `.topBarTrailing`.

```swift
// FIX:
ToolbarItemGroup(placement: .topBarLeading) { ... }
ToolbarItemGroup(placement: .topBarTrailing) { ... }
```

### H2 — No Empty Document State in ChapterList
**File:** `src/views/ChapterListView.swift`
**Issue:** When a brand new document is created with no chapters (empty `chapters` array before `selectFirstChapter()` runs), the `List` is empty with no prompt. The add button in the toolbar is tiny and easy to miss.

```swift
// FIX — add to ChapterListView body:
if viewModel.document.chapters.isEmpty {
    ContentUnavailableView {  // or custom VStack for iOS 16
        Label("No Chapters", systemImage: "doc.text")
    } actions: {
        Button("Add Chapter") { viewModel.addChapter() }
            .buttonStyle(.borderedProminent)
    }
}
```

### H3 — `BookSettingsView` Empty Init Flash
**File:** `src/views/BookSettingsView.swift:18-22`
**Issue:** `init()` creates an empty `BookMetadata()` which populates in `onAppear`. On slow devices this can cause a visible flash of empty fields before the real data loads.

```swift
// FIX — accept viewModel in init and initialize State directly:
// Use @EnvironmentObject workaround via a wrapper view or pass metadata as a binding.
// Simplest: remove init() entirely, use @State var metadata = BookMetadata()
// and rely on onAppear (acceptable but add .animation(.none) to suppress flash).
```

### H4 — No Keyboard Dismiss on iPad in BookSettings Form
**File:** `src/views/BookSettingsView.swift`
**Issue:** On iPad, tapping outside the form doesn't dismiss the keyboard. The `TextEditor` for description especially stays open.

```swift
// FIX — add to form:
.scrollDismissesKeyboard(.interactively)
```

---

## MEDIUM Issues

### M1 — No First-Launch Welcome / Onboarding
**File:** `src/AvantGardeApp.swift`, `src/viewmodels/DocumentViewModel.swift`
**Issue:** First-time users open to a blank chapter with no explanation of the app's purpose, key features, or how to export. The value proposition (KDP + Google Play export, TTS, themes) is invisible.
**Recommendation:** Add a one-time welcome sheet triggered on first launch (`UserDefaults.standard.bool(forKey: "hasLaunchedBefore")`). 3 cards: write, theme, export.

### M2 — Theme Changes Not Reflected in Chapter List Background
**File:** `src/views/ChapterListView.swift`
**Issue:** The chapter list sidebar uses `.listStyle(.sidebar)` which has a system background — it ignores `themeManager.currentTheme.colors.sidebar`. Dark themes (Mystery, Futuristic) look jarring because the sidebar stays white/gray.

```swift
// FIX — add to ChapterListView:
.scrollContentBackground(.hidden)
.background(themeManager.currentTheme.colors.sidebar)
```

### M3 — TTS Player Has No Volume Control
**File:** `src/views/TTSPlayerView.swift`
**Issue:** Speed and voice are configurable but volume is not exposed in the UI. `AudioController.setSpeechVolume()` exists but is unreachable from the UI. Minor but users will want volume independent of system volume for audiobook-style use.

### M4 — Export Button Shows ProgressView During Export but Doesn't Disable Menu
**File:** `src/views/ContentView.swift:93-100`
**Issue:** The export `Menu` still opens during `isExporting`. Tapping "Export for KDP" while KDP is already exporting starts a second concurrent export task.

```swift
// FIX:
.disabled(viewModel.isExporting)
```

### M5 — ThemePickerView Color Swatches Are Small (iPhone SE)
**File:** `src/views/ThemePickerView.swift:42-50`
**Issue:** The swatch `frame(height: 32)` inside a 150px minimum card works on Pro Max but is cramped on iPhone SE (375pt wide). The `LazyVGrid` with `adaptive(minimum: 150)` on SE width fits exactly 2 columns at 150pt each — tight with 16pt padding.
**Recommendation:** Reduce minimum to 140 or add a single-column layout for very narrow screens.

---

## LOW Issues

### L1 — `ChapterEditorView` Focus Trigger Uses DispatchQueue
**File:** `src/views/ChapterEditorView.swift:109-112`
**Issue:** `DispatchQueue.main.asyncAfter` for focus is a timing hack. Use `.task` for cleaner lifecycle.

### L2 — Status Bar Word Count Not Live During Typing
**File:** `src/views/ContentView.swift` (StatusBar)
**Issue:** `viewModel.wordCount` is a computed property on `EbookDocument`. Since `EbookDocument` is a class (reference type), SwiftUI won't re-render the `StatusBar` when its content changes because `@Published var document` only fires when the reference itself changes. The word count will be stale between auto-saves.
**Fix:** Change `wordCount` in `DocumentViewModel` to a `@Published var wordCount: Int = 0` that's updated in `updateChapterContent()`.

### L3 — No Scroll Position Memory
**File:** `src/views/ChapterEditorView.swift`
**Issue:** Switching chapters loses scroll position. A long chapter returns to top on re-selection.

---

## Positive Findings

- `NavigationSplitView` with `.balanced` style is correct for iPad two-column layout
- Theme system properly uses SwiftUI `Color` — all 12 themes render correctly on both platforms
- `ChapterEditorView` re-init via `.id(id)` is the correct SwiftUI pattern for replacing editor state on selection change
- Toolbar actions are logically grouped and discoverable
- All AppKit dependencies are gone — codebase is genuinely cross-platform

---

## Summary Table

| Severity | Count | Status |
|----------|-------|--------|
| Critical | 3 | Fix before TestFlight |
| High | 4 | Fix before TestFlight |
| Medium | 5 | Fix before v1.0 |
| Low | 3 | v1.1 polish |
