import Foundation
import AppKit

struct Chapter {
    var title: String
    var content: String
    var id: UUID = UUID()
    
    init(title: String, content: String) {
        self.title = title
        self.content = content
    }
}

struct BookMetadata {
    var title: String = ""
    var author: String = ""
    var description: String = ""
    var keywords: [String] = []
    var isbn: String = ""
    var publishDate: Date = Date()
    var genre: String = ""
    var language: String = "en"
    var coverImagePath: String = ""
}

struct FormattingRules {
    var fontSize: CGFloat = 12
    var fontName: String = "Times New Roman"
    var lineSpacing: CGFloat = 1.5
    var paragraphSpacing: CGFloat = 6
    var marginTop: CGFloat = 72
    var marginBottom: CGFloat = 72
    var marginLeft: CGFloat = 72
    var marginRight: CGFloat = 72
    var chapterStartsNewPage: Bool = true
}

class EbookDocument: NSDocument {
    var chapters: [Chapter] = []
    var metadata: BookMetadata = BookMetadata()
    var formatting: FormattingRules = FormattingRules()
    
    override init() {
        super.init()
        // Create a default first chapter
        chapters.append(Chapter(title: "Chapter 1", content: ""))
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }
    
    override func makeWindowControllers() {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        if let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("DocumentWindowController")) as? NSWindowController {
            self.addWindowController(windowController)
        }
    }
    
    override func data(ofType typeName: String) throws -> Data {
        // Serialize the document to data
        let documentData = DocumentData(
            chapters: chapters,
            metadata: metadata,
            formatting: formatting
        )
        
        return try JSONEncoder().encode(documentData)
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        // Deserialize the document from data
        let documentData = try JSONDecoder().decode(DocumentData.self, from: data)
        
        chapters = documentData.chapters
        metadata = documentData.metadata
        formatting = documentData.formatting
    }
    
    // MARK: - Chapter Management
    
    func addChapter(title: String = "", content: String = "") {
        let newChapter = Chapter(
            title: title.isEmpty ? "Chapter \(chapters.count + 1)" : title,
            content: content
        )
        chapters.append(newChapter)
    }
    
    func removeChapter(at index: Int) {
        guard index >= 0 && index < chapters.count else { return }
        chapters.remove(at: index)
    }
    
    func moveChapter(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex >= 0 && sourceIndex < chapters.count &&
              destinationIndex >= 0 && destinationIndex < chapters.count else { return }
        
        let chapter = chapters.remove(at: sourceIndex)
        chapters.insert(chapter, at: destinationIndex)
    }
    
    // MARK: - Export Functions
    
    func exportToKDP() throws -> Data {
        let kdpConverter = KDPConverter()
        return try kdpConverter.convertToKDP(document: self)
    }
    
    func exportToGoogle() throws -> Data {
        let googleConverter = GoogleConverter()
        return try googleConverter.convertToGoogle(document: self)
    }
    
    func exportToEPUB() throws -> Data {
        // EPUB export implementation
        let epubData = generateEPUBData()
        return epubData
    }
    
    private func generateEPUBData() -> Data {
        // Basic EPUB structure generation
        let content = chapters.map { "\($0.title)\n\n\($0.content)" }.joined(separator: "\n\n---\n\n")
        return content.data(using: .utf8) ?? Data()
    }
    
    // MARK: - Validation
    
    func validateForPlatform(_ platform: PublishingPlatform) -> [ValidationError] {
        let formattingEngine = FormattingEngine()
        
        let fullText = NSMutableAttributedString()
        for chapter in chapters {
            let chapterText = NSAttributedString(string: "\(chapter.title)\n\n\(chapter.content)\n\n")
            fullText.append(chapterText)
        }
        
        return formattingEngine.validateForPlatform(platform, text: fullText)
    }
    
    // MARK: - Statistics
    
    func getWordCount() -> Int {
        return chapters.reduce(0) { total, chapter in
            let words = chapter.content.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            return total + words.count
        }
    }
    
    func getCharacterCount() -> Int {
        return chapters.reduce(0) { total, chapter in
            return total + chapter.content.count
        }
    }
    
    func getEstimatedReadingTime() -> TimeInterval {
        let wordCount = getWordCount()
        let averageWordsPerMinute = 250.0
        return TimeInterval(Double(wordCount) / averageWordsPerMinute * 60)
    }
}

// MARK: - Codable Support

struct DocumentData: Codable {
    let chapters: [Chapter]
    let metadata: BookMetadata
    let formatting: FormattingRules
}

extension Chapter: Codable {}
extension BookMetadata: Codable {}
extension FormattingRules: Codable {}
