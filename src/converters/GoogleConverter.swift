import Foundation

class GoogleConverter: Converter {

    // MARK: - Async API

    func convertToGoogle(document: EbookDocument) async throws -> Data {
        Logger.info("Starting Google Play Books EPUB conversion for: \(document.metadata.title)", category: .conversion)
        return try await Task.detached(priority: .userInitiated) {
            try self.convertToGoogleSync(document: document)
        }.value
    }

    func convertFromGoogle(data: Data) async throws -> EbookDocument {
        return try await Task.detached(priority: .userInitiated) {
            try self.convertFromGoogleSync(data: data)
        }.value
    }

    // MARK: - Synchronous Implementation

    private func convertToGoogleSync(document: EbookDocument) throws -> Data {
        // Use local formatting copy — avoids mutating the shared document reference
        var googleFormatting = document.formatting
        googleFormatting.fontSize = 11
        googleFormatting.fontName = "Arial"
        googleFormatting.lineSpacing = 1.2
        googleFormatting.chapterStartsNewPage = true

        let epubContent = generateGoogleEPUB(document)

        guard let data = epubContent.data(using: .utf8), !data.isEmpty else {
            Logger.error("Failed to generate EPUB data", error: ConversionError.parsingFailed, category: .conversion)
            throw ConversionError.parsingFailed
        }

        Logger.info("Google EPUB conversion completed. Size: \(data.count) bytes", category: .conversion)
        return data
    }

    private func convertFromGoogleSync(data: Data) throws -> EbookDocument {
        guard let content = String(data: data, encoding: .utf8) else {
            throw ConversionError.invalidData
        }
        let document = EbookDocument()
        document.chapters = parseGoogleChapters(from: content)
        document.metadata = parseGoogleMetadata(from: content)
        return document
    }

    // MARK: - HTML / EPUB Generation

    private func generateGoogleEPUB(_ document: EbookDocument) -> String {
        var content = generateEPUBHeader(document.metadata)
        content += generateTableOfContents(document.chapters)
        for chapter in document.chapters {
            content += generateEPUBChapter(chapter)
        }
        content += generateEPUBFooter()
        return content
    }

    private func generateEPUBHeader(_ metadata: BookMetadata) -> String {
        let identifier = metadata.isbn.isEmpty
            ? "urn:uuid:\(UUID().uuidString)"
            : "urn:isbn:\(metadata.isbn.htmlEscaped)"

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="\(metadata.language)">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            <title>\(metadata.title.htmlEscaped)</title>
            <meta name="dc:title" content="\(metadata.title.htmlEscaped)"/>
            <meta name="dc:creator" content="\(metadata.author.htmlEscaped)"/>
            <meta name="dc:publisher" content="\(metadata.publisher.htmlEscaped)"/>
            <meta name="dc:identifier" content="\(identifier)"/>
            <meta name="dc:language" content="\(metadata.language)"/>
            <meta name="dc:rights" content="\(metadata.rights.htmlEscaped)"/>
            <meta name="dc:date" content="\(metadata.publicationDate)"/>
            <meta name="dc:description" content="\(metadata.description.htmlEscaped)"/>
            <meta name="author" content="\(metadata.author.htmlEscaped)"/>
            <meta name="generator" content="Avant Garde Ebook Authoring"/>
            <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
            <style type="text/css">
                body { font-family: Arial, 'Helvetica Neue', sans-serif; font-size: 11pt; line-height: 1.2; margin: 1.5em; text-align: justify; }
                h1 { font-size: 1.5em; font-weight: bold; text-align: center; page-break-before: always; margin: 1.5em 0; }
                p { text-indent: 1.5em; margin: 0; margin-bottom: 0.5em; text-align: justify; orphans: 2; widows: 2; }
                .chapter { page-break-after: always; }
                .toc { page-break-after: always; }
                .toc ul { list-style-type: none; padding-left: 0; }
                .toc li { margin: 0.5em 0; }
                img { max-width: 100%; height: auto; }
            </style>
        </head>
        <body>

        """
    }

    private func generateTableOfContents(_ chapters: [Chapter]) -> String {
        var toc = "<div class=\"toc\">\n    <h1>Table of Contents</h1>\n    <ul>\n"
        for (index, chapter) in chapters.enumerated() {
            toc += "        <li><a href=\"#chapter\(index + 1)\">\(chapter.title.htmlEscaped)</a></li>\n"
        }
        toc += "    </ul>\n</div>\n\n"
        return toc
    }

    private func generateEPUBChapter(_ chapter: Chapter) -> String {
        let formattedContent = formatChapterContent(chapter.content)
        return """
        <div class="chapter" id="chapter\(chapter.id.uuidString)">
            <h1>\(chapter.title.htmlEscaped)</h1>
        \(formattedContent)
        </div>

        """
    }

    private func formatChapterContent(_ content: String) -> String {
        let paragraphs = content.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return paragraphs.map { paragraph in
            let withBreaks = paragraph.htmlEscaped.replacingOccurrences(of: "\n", with: "<br/>\n")
            return "        <p>\(withBreaks)</p>"
        }.joined(separator: "\n")
    }

    private func generateEPUBFooter() -> String {
        return "</body>\n</html>"
    }

    // MARK: - Parsing

    private func parseGoogleChapters(from content: String) -> [Chapter] {
        var chapters: [Chapter] = []
        let pattern = #"<h1[^>]*>(.*?)</h1>(.*?)(?=<h1|</body>)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) else { return chapters }
        let nsContent = content as NSString
        regex.enumerateMatches(in: content, range: NSRange(location: 0, length: content.count)) { match, _, _ in
            guard let match = match else { return }
            let title = nsContent.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
            let chapterContent = nsContent.substring(with: match.range(at: 2))
                .replacingOccurrences(of: "<p>", with: "")
                .replacingOccurrences(of: "</p>", with: "\n\n")
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            chapters.append(Chapter(title: title, content: chapterContent))
        }
        return chapters
    }

    private func parseGoogleMetadata(from content: String) -> BookMetadata {
        var metadata = BookMetadata()
        if let range = content.range(of: #"<title>(.*?)</title>"#, options: .regularExpression) {
            metadata.title = String(content[range])
                .replacingOccurrences(of: "<title>", with: "")
                .replacingOccurrences(of: "</title>", with: "")
        }
        if let range = content.range(of: #"name="author" content="(.*?)""#, options: .regularExpression) {
            metadata.author = String(content[range])
                .replacingOccurrences(of: "name=\"author\" content=\"", with: "")
                .replacingOccurrences(of: "\"", with: "")
        }
        return metadata
    }

    // MARK: - Validation

    func validateForGooglePlayBooks(_ document: EbookDocument) -> [EPUBValidationError] {
        Logger.info("Validating document for Google Play Books requirements", category: .conversion)
        var errors: [EPUBValidationError] = []

        if document.metadata.title.isEmpty { errors.append(.missingMetadata(field: "title")) }
        if document.metadata.author.isEmpty { errors.append(.missingMetadata(field: "author")) }
        if document.metadata.language.isEmpty { errors.append(.missingMetadata(field: "language")) }
        if document.chapters.isEmpty { errors.append(.emptyContent) }

        for (index, chapter) in document.chapters.enumerated() {
            if chapter.title.isEmpty { errors.append(.emptyChapterTitle(chapterIndex: index)) }
            if chapter.content.isEmpty { errors.append(.emptyChapterContent(chapterIndex: index)) }
            let size = chapter.content.utf8.count
            if size > 300_000 { errors.append(.chapterTooLarge(chapterIndex: index, size: size)) }
            let combined = chapter.title + chapter.content
            if combined.contains("<script") || combined.contains("<iframe") { errors.append(.unsafeHTML(chapterIndex: index)) }
            let specialCharCount = combined.unicodeScalars.filter { $0.value > 127 }.count
            if specialCharCount > combined.count / 10 { errors.append(.excessiveSpecialCharacters(chapterIndex: index)) }
        }

        let totalSize = document.chapters.reduce(0) { $0 + $1.content.utf8.count }
        if totalSize > 100_000_000 { errors.append(.epubTooLarge(size: totalSize)) }
        else if totalSize > 50_000_000 { errors.append(.epubLarge(size: totalSize)) }

        if document.metadata.publisher.isEmpty { errors.append(.missingRecommendedMetadata(field: "publisher")) }
        if document.metadata.description.isEmpty { errors.append(.missingRecommendedMetadata(field: "description")) }

        if errors.isEmpty {
            Logger.info("Document passed all Google Play Books validation checks", category: .conversion)
        } else {
            Logger.warning("Document has \(errors.count) Google Play Books validation issues", category: .conversion)
        }
        return errors
    }

    // MARK: - Converter Protocol

    func convert(from source: EbookFormat, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { completion(true) }
    }
}

// MARK: - EPUB Validation Errors

enum EPUBValidationError: Error, CustomStringConvertible {
    case missingMetadata(field: String)
    case missingRecommendedMetadata(field: String)
    case emptyContent
    case emptyChapterTitle(chapterIndex: Int)
    case emptyChapterContent(chapterIndex: Int)
    case chapterTooLarge(chapterIndex: Int, size: Int)
    case epubTooLarge(size: Int)
    case epubLarge(size: Int)
    case unsafeHTML(chapterIndex: Int)
    case excessiveSpecialCharacters(chapterIndex: Int)
    case invalidXHTML(details: String)
    case missingTableOfContents

    var description: String {
        switch self {
        case .missingMetadata(let f): return "Missing required metadata: \(f)"
        case .missingRecommendedMetadata(let f): return "Missing recommended metadata: \(f)"
        case .emptyContent: return "Document has no chapters"
        case .emptyChapterTitle(let i): return "Chapter \(i + 1) has no title"
        case .emptyChapterContent(let i): return "Chapter \(i + 1) has no content"
        case .chapterTooLarge(let i, let s): return "Chapter \(i + 1) is too large (\(s) bytes). Google recommends under 300KB"
        case .epubTooLarge(let s): return "EPUB is too large (\(s) bytes). Google Play Books allows up to 100MB"
        case .epubLarge(let s): return "EPUB is large (\(s) bytes). Consider splitting into multiple volumes"
        case .unsafeHTML(let i): return "Chapter \(i + 1) contains unsafe HTML (script, iframe)"
        case .excessiveSpecialCharacters(let i): return "Chapter \(i + 1) has many special characters that may not render correctly"
        case .invalidXHTML(let d): return "Invalid XHTML: \(d)"
        case .missingTableOfContents: return "Document should include a table of contents"
        }
    }

    var severity: EPUBValidationSeverity {
        switch self {
        case .missingMetadata, .emptyContent, .epubTooLarge, .unsafeHTML, .invalidXHTML: return .error
        case .chapterTooLarge, .epubLarge, .excessiveSpecialCharacters, .emptyChapterTitle, .emptyChapterContent: return .warning
        case .missingRecommendedMetadata, .missingTableOfContents: return .info
        }
    }
}

enum EPUBValidationSeverity {
    case error
    case warning
    case info
}
