import AppKit
import Foundation

class TextEditor: NSViewController {
    // UI Elements - created programmatically
    private var textView: NSTextView!
    private var formatToolbar: NSToolbar!
    private var scrollView: NSScrollView!

    private var currentDocument: EbookDocument?
    private var undoManager: UndoManager = UndoManager()

    override func loadView() {
        // Create the main view
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        setupUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
        setupToolbar()
    }

    private func setupUI() {
        // Create scroll view
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Create text view
        textView = NSTextView(frame: scrollView.bounds)
        scrollView.documentView = textView

        // Set up constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTextView() {
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: view.frame.width, height: CGFloat.greatestFiniteMagnitude)

        // Connect undo manager
        textView.undoManager = undoManager

        // Enable automatic text substitution
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true

        // Set delegate for text change notifications
        textView.delegate = self

        Logger.debug("Text view configured with undo support", category: .editor)
    }

    private func setupToolbar() {
        // Toolbar is now handled by EditorWindowController
        // This method kept for compatibility
        Logger.debug("Toolbar setup called (handled by window controller)", category: .editor)
    }
    
    // MARK: - Rich text editing capabilities
    
    @objc func applyBold(_ sender: Any) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        
        textStorage.addAttribute(.font, 
                                value: NSFont.boldSystemFont(ofSize: 14), 
                                range: range)
    }
    
    @objc func applyItalic(_ sender: Any) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        
        let font = NSFont.systemFont(ofSize: 14)
        let italicFont = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        
        textStorage.addAttribute(.font, value: italicFont, range: range)
    }
    
    @objc func insertChapter(_ sender: Any) {
        let chapterBreak = "\n\n--- Chapter ---\n\n"
        textView.insertText(chapterBreak, replacementRange: textView.selectedRange())
    }
    
    @objc func addFootnote(_ sender: Any) {
        let footnoteText = "[Footnote: ]"
        textView.insertText(footnoteText, replacementRange: textView.selectedRange())
        
        // Move cursor to inside the footnote brackets
        let currentRange = textView.selectedRange()
        textView.setSelectedRange(NSRange(location: currentRange.location - 1, length: 0))
    }
    
    @objc func insertImage(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.image]
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                self.insertImageAtURL(url)
            }
        }
    }
    
    private func insertImageAtURL(_ url: URL) {
        guard let image = NSImage(contentsOf: url) else { return }
        
        let textAttachment = NSTextAttachment()
        textAttachment.image = image
        
        let attributedString = NSAttributedString(attachment: textAttachment)
        textView.insertText(attributedString, replacementRange: textView.selectedRange())
    }
    
    // MARK: - Document Management
    
    func loadDocument(_ document: EbookDocument) {
        Logger.info("Loading document: \(document.metadata.title) with \(document.chapters.count) chapters", category: .editor)

        currentDocument = document
        displayDocumentContent()

        // Clear undo stack for fresh document
        undoManager.removeAllActions()
        Logger.debug("Document loaded and undo stack cleared", category: .editor)
    }

    private func displayDocumentContent() {
        guard let document = currentDocument else {
            Logger.warning("Attempted to display content with no current document", category: .editor)
            return
        }

        let fullText = NSMutableAttributedString()

        for (index, chapter) in document.chapters.enumerated() {
            // Add chapter separator if not first chapter
            if index > 0 {
                let separator = NSAttributedString(string: "\n\n--- Chapter ---\n\n")
                fullText.append(separator)
            }

            // Add chapter title
            let chapterTitle = NSAttributedString(
                string: "\(chapter.title)\n\n",
                attributes: [
                    .font: NSFont.boldSystemFont(ofSize: 18),
                    .paragraphStyle: createCenteredParagraphStyle()
                ]
            )
            fullText.append(chapterTitle)

            // Add chapter content
            let chapterContent = NSAttributedString(
                string: "\(chapter.content)\n\n"
            )
            fullText.append(chapterContent)
        }

        textView.textStorage?.setAttributedString(fullText)
        Logger.debug("Displayed \(document.chapters.count) chapters (\(fullText.length) characters)", category: .editor)
    }

    /// Check if the current document has unsaved changes
    func hasUnsavedChanges() -> Bool {
        return currentDocument?.isDocumentEdited ?? false
    }

    /// Get word count from current text
    func getWordCount() -> Int {
        let text = textView.textStorage?.string ?? ""
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.count
    }

    /// Get character count from current text
    func getCharacterCount() -> Int {
        return textView.textStorage?.string.count ?? 0
    }
    
    private func createCenteredParagraphStyle() -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return paragraphStyle
    }
    
    func saveDocument() {
        guard let document = currentDocument else {
            Logger.warning("Attempted to save with no current document", category: .editor)
            return
        }

        Logger.info("Saving document: \(document.metadata.title)", category: .editor)

        // Extract chapters from the text view content
        let fullText = textView.textStorage?.string ?? ""
        document.chapters = parseChaptersFromText(fullText)

        // Mark document as having been edited
        document.updateChangeCount(.changeDone)

        Logger.info("Document updated with \(document.chapters.count) chapters", category: .editor)
    }

    /// Returns the current document for external save operations
    func getCurrentDocument() -> EbookDocument? {
        return currentDocument
    }
    
    private func parseChaptersFromText(_ text: String) -> [Chapter] {
        Logger.debug("Parsing chapters from text (\(text.count) characters)", category: .editor)

        let chapterSeparator = "--- Chapter ---"
        let chapterSections = text.components(separatedBy: chapterSeparator)

        var chapters: [Chapter] = []

        for (index, section) in chapterSections.enumerated() {
            let trimmed = section.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            // Try to extract chapter title from first line if it looks like a title
            let lines = trimmed.components(separatedBy: .newlines)
            var title = "Chapter \(chapters.count + 1)"
            var content = trimmed

            if let firstLine = lines.first, !firstLine.isEmpty {
                // If first line is short and looks like a title (all caps, or ends with colon, or less than 100 chars)
                let potentialTitle = firstLine.trimmingCharacters(in: .whitespaces)
                if potentialTitle.count < 100 &&
                   (potentialTitle == potentialTitle.uppercased() ||
                    potentialTitle.contains("Chapter") ||
                    potentialTitle.hasSuffix(":")) {
                    title = potentialTitle
                    // Remove title from content
                    let contentLines = lines.dropFirst()
                    content = contentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

            let chapter = Chapter(title: title, content: content)
            chapters.append(chapter)
        }

        Logger.debug("Parsed \(chapters.count) chapters", category: .editor)
        return chapters
    }

    // MARK: - Undo/Redo Support

    @objc func undo() {
        undoManager.undo()
        Logger.debug("Undo performed", category: .editor)
    }

    @objc func redo() {
        undoManager.redo()
        Logger.debug("Redo performed", category: .editor)
    }

    var canUndo: Bool {
        return undoManager.canUndo
    }

    var canRedo: Bool {
        return undoManager.canRedo
    }
}

// MARK: - NSTextViewDelegate

extension TextEditor: NSTextViewDelegate {

    func textDidChange(_ notification: Notification) {
        // Mark document as changed when text is edited
        if let document = currentDocument {
            document.updateChangeCount(.changeDone)
            Logger.debug("Document marked as changed", category: .editor)
        }
    }

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // Handle special commands if needed
        switch commandSelector {
        case #selector(NSResponder.insertTab(_:)):
            // Insert actual tab character instead of moving focus
            textView.insertText("\t", replacementRange: textView.selectedRange())
            return true
        default:
            return false
        }
    }
}
