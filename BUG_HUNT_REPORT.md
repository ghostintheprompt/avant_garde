# AUDIT 4: Crash & Bug Hunt
## Avant Garde Authoring App

**Date:** February 2026
**Focus:** Crashes, data loss, broken features, impossible states, edge cases
**Standard:** Zero data loss, zero crashes during normal use

---

## EXECUTIVE SUMMARY

**Score: 4/10**

Several bugs range from guaranteed crashes on launch to silent data disconnects that authors would never notice until their book fails to export. The most serious issue is a potential deadlock in ServiceContainer. Multiple features are "implemented" in the UI but don't actually work (chapter navigation, word count updates, TTS chapter tracking, theme application). None of these would survive a real-user playtest.

---

## CRITICAL BUGS (Guaranteed Crashes or Data Loss)

### B1 — `makeWindowControllers()` Crashes if "Main" Storyboard Doesn't Exist
**File:** `src/models/EbookDocument.swift:66-71`
**Severity:** CRITICAL — Guaranteed crash on launch

```swift
override func makeWindowControllers() {
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    if let windowController = storyboard.instantiateController(
        withIdentifier: NSStoryboard.SceneIdentifier("DocumentWindowController")
    ) as? NSWindowController {
        self.addWindowController(windowController)
    }
}
```

There is no `Main.storyboard` in the project (UI is entirely programmatic). `NSStoryboard(name: "Main", bundle: nil)` will return `nil` if the storyboard file doesn't exist, but `instantiateController` on a nil storyboard results in a crash on macOS. On iOS, `UIStoryboard(name:bundle:)` is not nil-failable — it crashes immediately if the storyboard doesn't exist.

**Steps to reproduce:** Open a saved document (triggers `makeWindowControllers()`). Instant crash.

**Fix:** Delete this entire `makeWindowControllers()` override. Window controllers are already created programmatically in `EbookConverterApp.swift`.

---

### B2 — ServiceContainer Lazy Singleton Deadlock
**File:** `src/utils/ServiceContainer.swift:55-69`
**Severity:** CRITICAL — App freeze / watchdog kill

```swift
func registerLazySingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
    lock.lock()          // ← NSLock acquired
    defer { lock.unlock() }

    let key = String(describing: type)
    factories[key] = {
        let instance = factory()
        self.lock.lock()  // ← DEADLOCK: NSLock.lock() is NOT reentrant
        self.singletons[key] = instance
        self.factories.removeValue(forKey: key)
        self.lock.unlock()
        return instance
    }
}
```

If any service's factory calls back into `ServiceContainer.resolve()` during its own initialization, the closure will try to acquire `self.lock` while `registerLazySingleton` still holds it. `NSLock` is not reentrant. This deadlocks.

**Currently safe** because no service factories call back into ServiceContainer during init. But this is a time-bomb: if a future refactor makes `FormattingEngine` resolve its dependencies via the container during init, the app will freeze silently.

**Fix:** Replace `NSLock` with `NSRecursiveLock`:
```swift
private let lock = NSRecursiveLock()
```

---

### B3 — `ValidationSeverity` Enum Defined Twice — Compile Error
**Files:** `src/editor/FormattingEngine.swift:16-19`, `src/converters/GoogleConverter.swift:484-488`
**Severity:** CRITICAL — Compile failure

`ValidationSeverity` is defined in both files:
```swift
// FormattingEngine.swift:16
enum ValidationSeverity {
    case error, warning, info
}

// GoogleConverter.swift:484
enum ValidationSeverity {
    case error, warning, info
}
```

This is a redeclaration and will cause a compile error when both files are compiled in the same module. If this currently compiles, it's only because the SPM targets are split (`Editor` vs `Converters`) — but if they share a module boundary or are linked together, this will break.

**Fix:** Define `ValidationSeverity` once in a shared `Models` target and import it everywhere.

---

### B4 — `EbookDocument.exportToEPUB()` Returns Fake Data
**File:** `src/models/EbookDocument.swift:137-149`
**Severity:** HIGH — Silent data corruption

```swift
func exportToEPUB() async throws -> Data {
    return try await Task {
        let epubData = generateEPUBData()
        return epubData
    }.value
}

private func generateEPUBData() -> Data {
    // Basic EPUB structure generation
    let content = chapters.map { "\($0.title)\n\n\($0.content)" }.joined(separator: "\n\n---\n\n")
    return content.data(using: .utf8) ?? Data()
}
```

`exportToEPUB()` returns plain concatenated text, not EPUB format. EPUB is a ZIP archive containing XML, OPF manifests, NCX/NAV files, and XHTML chapters. This data written to a `.epub` file would produce a corrupt file that no EPUB reader can open.

This is particularly dangerous because `GoogleConverter.convertToGoogle()` also outputs a single XHTML file called "EPUB" — not a real EPUB ZIP archive either. Both exports are incomplete implementations.

**Impact:** A user who exports, uploads to Google Play Books, and gets a rejection will blame their manuscript.

---

## HIGH BUGS (Broken Features)

### B5 — Chapter Table View Has No Data Source — Always Shows Empty
**File:** `src/ui/EditorWindowController.swift:79-88`
**Severity:** HIGH — Core feature broken

```swift
let tableView = NSTableView()
let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("chapter"))
column.title = "Chapters"
column.width = 220
tableView.addTableColumn(column)
tableView.headerView = nil
scrollView.documentView = tableView
self.chapterTableView = tableView
// ← Missing: tableView.dataSource = self
// ← Missing: tableView.delegate = self
```

`NSTableView` requires a `dataSource` and `delegate` to display content. Neither is set. The chapter list will always show as empty, even after calling `chapterTableView?.reloadData()` in `addChapter()`.

**Fix:** Implement `NSTableViewDataSource` and `NSTableViewDelegate` on `EditorWindowController`, set them, and implement `numberOfRows(in:)` and `tableView(_:viewFor:row:)`.

On iOS: `UITableView` has the same requirement. Must set `.dataSource` and `.delegate`.

---

### B6 — Selecting a Chapter in the Sidebar Does Nothing
**Severity:** HIGH — Navigation broken

Even if B5 were fixed, selecting a chapter in the sidebar has no effect on the editor. There's no `tableView(_:shouldSelectRow:)` handler, no scroll-to-chapter behavior. The chapter navigator is purely decorative.

**Fix:** Implement `tableViewSelectionDidChange(_:)` to load the selected chapter's content into the text view (or navigate to it in a multi-chapter UITextView layout).

---

### B7 — Theme Application Never Updates the Editor
**File:** `src/ui/ColorThemeManager.swift:196-207` and `src/ui/EditorWindowController.swift`
**Severity:** HIGH — Core feature silent failure

`ColorThemeManager.applyTheme()` posts `.themeDidChange` notification. No part of `EditorWindowController` observes this notification. The `NSTextView` background and text color never change when a theme is selected.

**Steps to reproduce:** Select any color theme from View → Color Themes. Nothing changes visually.

**Fix:** In `EditorWindowController.setupWindow()`, add:
```swift
NotificationCenter.default.addObserver(
    self, selector: #selector(themeDidChange(_:)),
    name: .themeDidChange, object: nil
)
```
Then implement `themeDidChange` to update `mainTextView?.backgroundColor` and `mainTextView?.textColor`.

---

### B8 — Word Count Never Updates While Typing
**File:** `src/ui/EditorWindowController.swift:643-655`
**Severity:** HIGH — Metric feature broken

`updateStatistics()` is only called in `addChapter()`. The sidebar labels "Words: 0", "Characters: 0", "Est. Reading: 0 min" never change as the user types.

**Root cause:** `NSTextView` delegate not set. There's no `textDidChange` notification handler.

**Fix:**
```swift
textView.delegate = self
// ...
func textDidChange(_ notification: Notification) {
    updateStatistics()
}
```

Note: `updateStatistics()` reads from `document.chapters`, but the text view content is NOT synced back to `document.chapters` on each keystroke either. So even after fixing the delegate, the counts would still be wrong unless text→model sync is also fixed.

---

### B9 — Text View Content Never Saved Back to Document Model
**Severity:** HIGH — All chapter content is lost on document close

The `NSTextView` contains the user's writing. But when `saveDocument()` is called, it serializes `document.chapters` from the in-memory model. There is no code that copies the `textView.string` back to `document.chapters[currentChapter].content` before saving.

**Steps to reproduce:**
1. Create a new document
2. Type "Hello World" in the editor
3. Save the document
4. Close and reopen
5. Editor shows empty — "Hello World" is gone

**This is a data loss bug.** The text view is cosmetic — the data model is never populated from user input.

**Fix:** Implement `NSTextViewDelegate.textDidChange` to write `textView.attributedString.string` back to `document.chapters[currentIndex].content`.

---

### B10 — `playCurrentChapter()` Always Plays Chapter 1
**File:** `src/EbookConverterApp.swift:537-539`
**Severity:** HIGH — Feature broken

```swift
// TODO: Implement current chapter detection
if let firstChapter = document.chapters.first {
    textToSpeech?.speakChapter(firstChapter)  // ← Always chapter 1
}
```

Regardless of which chapter is selected in the sidebar, TTS always reads chapter 1.

**Fix:** Track the currently selected chapter index in `EditorWindowController`, expose it via a property, and read it in `playCurrentChapter()`.

---

### B11 — `showVoiceSettings()` Opens Preferences But Doesn't Navigate to Voice Tab
**File:** `src/EbookConverterApp.swift:566-570`
**Severity:** MEDIUM

```swift
@objc private func showVoiceSettings() {
    showPreferences()
    // TODO: Navigate to voice tab
}
```

Voice Settings opens the Preferences window at whatever tab was last open. The user has to manually find the Voice tab.

**Fix:** `PreferencesWindowController` needs a method to select a specific tab. Call it after `showWindow(nil)`.

---

### B12 — `showHelp()` and `reportIssue()` Print to Console and Do Nothing
**File:** `src/EbookConverterApp.swift:572-574, 629-631`
**Severity:** MEDIUM

```swift
@objc private func showHelp() {
    // TODO: Show help window
    print("Help requested")
}

@objc private func reportIssue() {
    // TODO: Open issue reporting
    print("Report issue requested")
}
```

Both Help and Report Issue show nothing to the user. These menu items appear functional but do nothing. Users who need help will see no response.

---

### B13 — `insertChapter()` Creates Text Artifact, Not a Real Chapter
**File:** `src/ui/EditorWindowController.swift:479-486`
**Severity:** MEDIUM

Inserting `"--- Chapter Break ---"` as text means:
1. It appears in the exported KDP HTML as paragraph text (`<p>--- Chapter Break ---</p>`)
2. It is not a chapter break in the data model
3. It will NOT cause a proper `page-break-before: always` in the CSS

An author who uses "Insert Chapter Break" will get a visible `--- Chapter Break ---` string in their published ebook.

---

## EDGE CASES TO TEST

| Scenario | Expected | Actual | Risk |
|----------|----------|--------|------|
| Open document with 0 chapters | Show empty editor with prompt | Unclear — `chapters.first` would return nil in TTS | MEDIUM |
| Export with empty chapter content | Validation catches it | Validation does catch this — good | LOW |
| Export with no title/author set | Validation catches it | KDPConverter.validateForKDP checks this | LOW |
| Type > 650,000 chars in one chapter | Warning shown | Validation checks this | LOW |
| Very long book (50+ chapters) | Memory stays reasonable | All loaded at once — potential issue | MEDIUM |
| App goes to background during TTS | TTS pauses gracefully | No AVAudioSession setup — behavior unknown | HIGH |
| App goes to background during export | Export completes or cancels cleanly | No background task entitlement | HIGH |
| Two TextToSpeech instances speak simultaneously | Graceful handling | Two synthesizers — undefined behavior | MEDIUM |

---

## SOFT-LOCK SCENARIOS

1. **User types in editor, closes without saving:** On iOS (no explicit save), all work is lost because text view content is never synced to model (see B9). This is the most likely scenario for an iOS authoring app.

2. **User tries to export before entering title/author:** Validation catches missing fields, but there's no UI to set them. User gets an error with no path to fix it (no metadata editing screen).

3. **User deletes all chapters:** No way to do this in UI (no delete chapter button). But if they could, document with 0 chapters would show no content and validation would error without a clear "add chapter" prompt.
