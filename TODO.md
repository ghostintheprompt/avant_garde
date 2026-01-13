# Avant Garde - Development TODO (Realistic Assessment)

**Last Updated:** 2026-01-13
**Status:** 🔴 MAJOR IMPLEMENTATION WORK REQUIRED
**Based on:** LLM Code Audit Report

---

## 🚨 CRITICAL ISSUES - Must Fix Before ANY Release

### 1. ⚠️ Implement Empty Action Methods (40-60 hours)
**File:** `src/ui/EditorWindowController.swift`

All toolbar buttons are currently non-functional placeholders:
- [ ] `addChapter()` - Implement chapter creation logic
- [ ] `makeBold()` - Apply bold formatting to selected text
- [ ] `makeItalic()` - Apply italic formatting
- [ ] `makeUnderline()` - Apply underline
- [ ] `alignLeft()` - Set paragraph alignment
- [ ] `alignCenter()` - Center text
- [ ] `alignRight()` - Right align
- [ ] `insertChapter()` - Insert chapter break
- [ ] `insertImage()` - Add image picker and insertion
- [ ] `insertFootnote()` - Create footnote system
- [ ] `validateKDP()` - Connect to validation engine
- [ ] `validateGoogle()` - Connect to validation engine
- [ ] `playAudio()` - Connect to TextToSpeech
- [ ] `voiceSettings()` - Open voice preferences

### 2. ⚠️ Fix UI Architecture (20-30 hours)

**Option A: Remove all @IBOutlet references (RECOMMENDED)**
Files to fix:
- [ ] `src/ui/TextEditor.swift` - Remove @IBOutlet, use programmatic UI
- [ ] `src/ui/AudioViewController.swift` - Remove @IBOutlet, use programmatic UI
- [ ] `src/ui/VoiceSettingsViewController.swift` - Remove @IBOutlet, use programmatic UI
- [ ] `src/ui/ThemeSelectorViewController.swift` - Remove @IBOutlet, use programmatic UI

**Option B: Create XIB/Storyboard files**
- [ ] Create Main.storyboard
- [ ] Create TextEditor.xib
- [ ] Create AudioViewController.xib
- [ ] etc.

### 3. ⚠️ Fix Compilation Errors (4-6 hours)

- [ ] **ConversionViewController.swift**
  - Add `.unknown` case to EbookFormat enum
  - Create Converter protocol
  - Fix method call syntax errors
  - Make converters conform to protocol

- [ ] **FormatDetector.swift**
  - Rename `detectFormat(of:)` to `detectFormat(filePath:)` OR
  - Update EbookParser to use correct method signature

- [ ] **EbookFormat enum**
  ```swift
  enum EbookFormat: String, CaseIterable {
      case kdp = "KDP"
      case google = "Google Play"
      case epub = "EPUB"
      case pdf = "PDF"
      case mobi = "MOBI"
      case azw3 = "AZW3"
      case unknown = "Unknown"
  }
  ```

### 4. ⚠️ Fix Memory Leaks (2-4 hours)

- [ ] **ThemeSelectorViewController.swift:88** - Store and invalidate timer
- [ ] Audit all closures for `[weak self]` usage
- [ ] Add proper `deinit` methods where needed

### 5. ⚠️ Remove Demo Code from Main Source (1-2 hours)

- [ ] Move `ColorPsychologyDemo.swift` to `/demos` folder
- [ ] Move `VoiceDemo.swift` to `/demos` folder
- [ ] Update README to reference demos separately
- [ ] Fix incorrect reference to `EbookConverterApp` (should be `AvantGardeApp`)

---

## 🔴 HIGH PRIORITY - For Beta Release

### 6. Async/Await Implementation (10-15 hours)

Make long-running operations non-blocking:
- [ ] `KDPConverter.convertToKDP()` - Make async
- [ ] `GoogleConverter.convertToGoogle()` - Make async
- [ ] Update all callers to use `await`
- [ ] Add progress indicators during export

### 7. Proper Error Handling (6-8 hours)

Replace alert-only error handling:
- [ ] Add logging throughout (NSLog or os_log)
- [ ] Integrate crash reporting (optional)
- [ ] Handle specific error cases differently
- [ ] Create error recovery flows

### 8. Extract Duplicate Code (4-6 hours)

- [ ] Create `PreferencesHelpers` utility class
- [ ] Move `createSection`, `createCheckbox`, `createTextField` to shared location
- [ ] Update both GeneralPreferencesViewController and EditorPreferencesViewController

### 9. Complete TextEditor Integration (8-10 hours)

- [ ] Connect `loadDocument()` to actual document system
- [ ] Implement proper `saveDocument()` without calling `document.save(nil)`
- [ ] Fix chapter parsing and extraction
- [ ] Add undo/redo support

### 10. AudioController Integration (6-8 hours)

- [ ] Connect AudioViewController to AudioController properly
- [ ] Implement chapter-by-chapter navigation
- [ ] Add progress tracking UI
- [ ] Fix hardcoded "Your text goes here" placeholder

---

## 🟡 MEDIUM PRIORITY - For 1.0 Release

### 11. Format Detection (4-6 hours)

- [ ] Implement content-based format detection (not just extension)
- [ ] Add magic number/header checking
- [ ] Support all claimed formats

### 12. Complete Export System (8-12 hours)

- [ ] Finish KDP HTML generation with proper validation
- [ ] Complete Google EPUB with full metadata
- [ ] Test exports with actual KDP and Google Play uploads
- [ ] Add export validation and error reporting

### 13. Dependency Injection (10-15 hours)

- [ ] Create ServiceContainer or similar
- [ ] Inject AudioController instead of creating inline
- [ ] Inject TextToSpeech where needed
- [ ] Make code more testable

### 14. Add Unit Tests (20-30 hours)

Currently ZERO tests exist:
- [ ] Test ColorThemeManager theme selection
- [ ] Test KDPConverter output format
- [ ] Test GoogleConverter EPUB generation
- [ ] Test EbookDocument chapter management
- [ ] Test FormattingEngine validation
- [ ] Test TextToSpeech voice selection
- [ ] Test AudioController playback logic

### 15. Accessibility (6-8 hours)

- [ ] Add accessibility labels to all buttons
- [ ] Add accessibility identifiers for testing
- [ ] Test with VoiceOver
- [ ] Ensure keyboard navigation works

---

## 🟢 NICE TO HAVE - Future Versions

### 16. Enhanced Features
- [ ] Implement drag-and-drop chapter reordering
- [ ] Add image insertion with preview
- [ ] Create footnote management system
- [ ] Add auto-save functionality
- [ ] Implement document recovery

### 17. Performance
- [ ] Optimize for large documents (100k+ words)
- [ ] Add document streaming
- [ ] Implement background export
- [ ] Profile and optimize startup time

### 18. Polish
- [ ] Create app icon (all sizes)
- [ ] Add launch screen
- [ ] Implement keyboard shortcuts
- [ ] Add tooltips throughout
- [ ] Create contextual menus

---

## 📊 REALISTIC TIME ESTIMATES

### To Minimum Viable Product (MVP):
- **Critical Issues:** 80-100 hours
- **High Priority:** 50-70 hours
- **Testing & Bug Fixing:** 40-60 hours
- **Total:** 170-230 hours (~5-7 weeks full-time)

### To App Store Ready:
- Add Medium Priority tasks: +60-90 hours
- Add App Store prep: +20-30 hours
- **Total:** 250-350 hours (~8-12 weeks full-time)

---

## 🎯 RECOMMENDED DEVELOPMENT PHASES

### Phase 1: Make It Work (Weeks 1-3)
Focus on critical issues - get the app actually functional:
1. Fix compilation errors
2. Implement all empty action methods
3. Fix UI architecture (@IBOutlet issues)
4. Fix memory leaks

### Phase 2: Make It Stable (Weeks 4-5)
Focus on high priority issues:
1. Add async/await
2. Proper error handling
3. Complete audio integration
4. Basic testing

### Phase 3: Make It Good (Weeks 6-8)
Focus on medium priority:
1. Complete export system
2. Add unit tests
3. Fix duplicate code
4. Accessibility

### Phase 4: Make It Ship (Weeks 9-12)
App Store preparation:
1. Icons and assets
2. Screenshots
3. App Store metadata
4. Beta testing
5. Submission

---

## 🔍 WHAT'S ACTUALLY WORKING

To be clear about current state:

### ✅ FULLY WORKING:
- ColorThemeManager theme definitions
- ThemeColors and theme switching logic
- VoiceManager and voice listing
- Document model structure (Chapter, BookMetadata)
- Basic app menu structure

### ⚠️ PARTIALLY WORKING:
- EditorWindowController UI layout (but buttons do nothing)
- PreferencesWindow structure (but settings don't persist properly)
- Audio system architecture (but not connected to UI)

### ❌ NOT WORKING:
- All text formatting buttons
- Chapter creation/management UI
- Image insertion
- Footnote system
- Actual KDP/Google export testing
- Format validation
- Audio playback from UI
- Document save/load (broken)

---

## 📝 NOTES FROM AUDIT

**Key Finding:** This codebase has excellent architecture and design, but approximately 60% of the UI methods are empty placeholders. The core logic exists, but the connections between UI and logic are incomplete.

**Not a "Bad" Codebase:** The structure is professional and well-organized. It just needs the implementation work to connect all the pieces.

**LLM Generation Evidence:** Typical patterns of AI-generated code - good structure, comprehensive features, but many empty methods and incomplete implementations.

---

## 💡 STRATEGIC RECOMMENDATIONS

1. **Don't Rush to App Store** - 170+ hours of work remain
2. **Focus on Core First** - Get editing and export working before polish
3. **Test Early, Test Often** - Start writing tests now, not later
4. **Consider Pivot** - Maybe release as open-source alpha first?
5. **Get Real Users** - Beta test with actual authors ASAP
6. **Be Honest About Timeline** - 2-3 months minimum to App Store

---

## 🎯 SUCCESS DEFINITION

**Minimum for 1.0 Release:**
- All toolbar buttons functional
- Can create, edit, save, and load documents
- Can add and organize chapters
- Can export to KDP (tested with actual upload)
- Can export to Google Play (tested with actual upload)
- Audio playback works
- No crashes or data loss
- Passes App Store review guidelines

---

**Reality Check:** This is a great start on a professional application, but it needs significant implementation work before it's ready for users. The architecture is sound - now it needs the execution.
