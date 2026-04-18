import Foundation

struct Chapter: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var content: String {
        didSet {
            updateWordCount()
        }
    }

    private(set) var cachedWordCount: Int = 0

    init(title: String, content: String) {
        self.title = title
        self.content = content
        updateWordCount()
    }

    private mutating func updateWordCount() {
        cachedWordCount = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
}

struct BookMetadata: Codable {
    var title: String = ""
    var author: String = ""
    var description: String = ""
    var keywords: [String] = []
    var isbn: String = ""
    var publishDate: Date = Date()
    var genre: String = ""
    var language: String = "en"
    var coverImagePath: String = ""
    var publisher: String = ""
    var rights: String = "All rights reserved"
    var subject: String = ""

    // Layout Engine Integration
    var preset: StylePreset = .meridian
    var enableDropCaps: Bool = true
    var enableHyphenation: Bool = true

    var publicationDate: String {
        return BookMetadata.dateFormatter.string(from: publishDate)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

enum StylePreset: String, Codable, CaseIterable {
    case meridian = "Meridian"
    case serein = "Serein"
    case oxford = "Oxford"
    case vogue = "Vogue"
    case legible = "Legible"
}

struct FormattingRules: Codable {
    var fontSize: CGFloat = 12
    var fontName: String = "Times New Roman"
    var lineSpacing: CGFloat = 1.5
    var paragraphSpacing: CGFloat = 0 
    var chapterStartsNewPage: Bool = true
}

// MARK: - EbookDocument (plain class — no NSDocument dependency)

class EbookDocument {
    var chapters: [Chapter]
    var metadata: BookMetadata
    var formatting: FormattingRules

    init() {
        chapters = [Chapter(title: "Chapter 1", content: "")]
        metadata = BookMetadata()
        formatting = FormattingRules()
    }

    // MARK: - Serialization

    func toData() throws -> Data {
        let documentData = DocumentData(chapters: chapters, metadata: metadata, formatting: formatting)
        return try JSONEncoder().encode(documentData)
    }

    static func from(data: Data) throws -> EbookDocument {
        let documentData = try JSONDecoder().decode(DocumentData.self, from: data)
        let doc = EbookDocument()
        doc.chapters = documentData.chapters
        doc.metadata = documentData.metadata
        doc.formatting = documentData.formatting
        return doc
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

    // MARK: - Export

    func exportToKDP() async throws -> Data {
        return try await KDPConverter().convertToKDP(document: self)
    }

    func exportToGoogle() async throws -> Data {
        return try await GoogleConverter().convertToGoogle(document: self)
    }

    // MARK: - Validation

    func validateForKDP() -> ValidationReport {
        return ExportValidator().validate(document: self, for: .kdp)
    }

    func validateForGoogle() -> ValidationReport {
        return ExportValidator().validate(document: self, for: .google)
    }

    // MARK: - Statistics

    func getWordCount() -> Int {
        return chapters.reduce(0) { $0 + $1.cachedWordCount }
    }

    func getCharacterCount() -> Int {
        return chapters.reduce(0) { $0 + $1.content.count }
    }

    func getEstimatedReadingTime() -> TimeInterval {
        let wordCount = getWordCount()
        return TimeInterval(Double(wordCount) / 250.0 * 60)
    }
}

// MARK: - Codable Support

struct DocumentData: Codable {
    let chapters: [Chapter]
    let metadata: BookMetadata
    let formatting: FormattingRules
}
