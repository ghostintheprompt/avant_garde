import AppKit
import Foundation

class TextEditor: NSViewController {
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var formatToolbar: NSToolbar!
    
    private var currentDocument: EbookDocument?
    private var undoManager: UndoManager = UndoManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
        setupToolbar()
    }
    
    private func setupTextView() {
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: view.frame.width, height: CGFloat.greatestFiniteMagnitude)
    }
    
    private func setupToolbar() {
        // Configure formatting toolbar
        formatToolbar.displayMode = .iconOnly
    }
    
    // MARK: - Rich text editing capabilities
    
    @IBAction func applyBold(_ sender: Any) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        
        textStorage.addAttribute(.font, 
                                value: NSFont.boldSystemFont(ofSize: 14), 
                                range: range)
    }
    
    @IBAction func applyItalic(_ sender: Any) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        
        let font = NSFont.systemFont(ofSize: 14)
        let italicFont = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        
        textStorage.addAttribute(.font, value: italicFont, range: range)
    }
    
    @IBAction func insertChapter(_ sender: Any) {
        let chapterBreak = "\n\n--- Chapter ---\n\n"
        textView.insertText(chapterBreak, replacementRange: textView.selectedRange())
    }
    
    @IBAction func addFootnote(_ sender: Any) {
        let footnoteText = "[Footnote: ]"
        textView.insertText(footnoteText, replacementRange: textView.selectedRange())
        
        // Move cursor to inside the footnote brackets
        let currentRange = textView.selectedRange()
        textView.setSelectedRange(NSRange(location: currentRange.location - 1, length: 0))
    }
    
    @IBAction func insertImage(_ sender: Any) {
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
        currentDocument = document
        displayDocumentContent()
    }
    
    private func displayDocumentContent() {
        guard let document = currentDocument else { return }
        
        let fullText = NSMutableAttributedString()
        
        for chapter in document.chapters {
            let chapterTitle = NSAttributedString(
                string: "\(chapter.title)\n\n",
                attributes: [
                    .font: NSFont.boldSystemFont(ofSize: 18),
                    .paragraphStyle: createCenteredParagraphStyle()
                ]
            )
            fullText.append(chapterTitle)
            
            let chapterContent = NSAttributedString(
                string: "\(chapter.content)\n\n"
            )
            fullText.append(chapterContent)
        }
        
        textView.textStorage?.setAttributedString(fullText)
    }
    
    private func createCenteredParagraphStyle() -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return paragraphStyle
    }
    
    func saveDocument() {
        guard let document = currentDocument else { return }
        
        // Extract chapters from the text view content
        let fullText = textView.textStorage?.string ?? ""
        document.chapters = parseChaptersFromText(fullText)
        
        // Save the document
        document.save(nil)
    }
    
    private func parseChaptersFromText(_ text: String) -> [Chapter] {
        let chapterSeparator = "--- Chapter ---"
        let chapterSections = text.components(separatedBy: chapterSeparator)
        
        var chapters: [Chapter] = []
        
        for (index, section) in chapterSections.enumerated() {
            let trimmed = section.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let chapter = Chapter(
                    title: "Chapter \(index + 1)",
                    content: trimmed
                )
                chapters.append(chapter)
            }
        }
        
        return chapters
    }
}
