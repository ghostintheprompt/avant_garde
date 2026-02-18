import Foundation

class KDPConverter: Converter {

    // MARK: - Async API

    func convertToKDP(document: EbookDocument) async throws -> Data {
        Logger.info("Starting KDP conversion for: \(document.metadata.title)", category: .conversion)
        return try await Task.detached(priority: .userInitiated) {
            try self.convertToKDPSync(document: document)
        }.value
    }

    func convertFromKDP(data: Data) async throws -> EbookDocument {
        return try await Task.detached(priority: .userInitiated) {
            try self.convertFromKDPSync(data: data)
        }.value
    }

    // MARK: - Synchronous Implementation

    private func convertToKDPSync(document: EbookDocument) throws -> Data {
        guard !document.chapters.isEmpty else {
            Logger.warning("KDP conversion attempted on document with no chapters", category: .conversion)
            throw ConversionError.invalidData
        }

        Logger.debug("Converting \(document.chapters.count) chapters to KDP format", category: .conversion)

        // Use local formatting copy — avoids mutating the shared document reference
        var kdpFormatting = document.formatting
        kdpFormatting.fontSize = 12
        kdpFormatting.fontName = "Times New Roman"
        kdpFormatting.lineSpacing = 1.15
        kdpFormatting.chapterStartsNewPage = true

        var kdpContent = generateKDPHeader(document.metadata)
        for chapter in document.chapters {
            kdpContent += generateKDPChapter(chapter)
        }
        kdpContent += generateKDPFooter()

        guard let data = kdpContent.data(using: .utf8) else {
            throw ConversionError.parsingFailed
        }

        Logger.info("KDP conversion completed. Size: \(data.count) bytes", category: .conversion)
        return data
    }

    private func convertFromKDPSync(data: Data) throws -> EbookDocument {
        guard let content = String(data: data, encoding: .utf8) else {
            throw ConversionError.invalidData
        }
        let document = EbookDocument()
        document.chapters = parseKDPChapters(from: content)
        document.metadata = parseKDPMetadata(from: content)
        return document
    }

    // MARK: - HTML Generation

    private func generateKDPHeader(_ metadata: BookMetadata) -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="\(metadata.language)">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            <title>\(metadata.title.htmlEscaped)</title>
            <meta name="author" content="\(metadata.author.htmlEscaped)"/>
            <meta name="description" content="\(metadata.description.htmlEscaped)"/>
            <meta name="publisher" content="\(metadata.publisher.htmlEscaped)"/>
            <meta name="generator" content="Avant Garde Ebook Authoring"/>
            <style type="text/css">
                body { font-family: 'Times New Roman', serif; font-size: 12pt; line-height: 1.15; margin: 2em; text-align: justify; }
                h1 { font-size: 1.5em; font-weight: bold; text-align: center; page-break-before: always; margin: 1em 0; }
                p { text-indent: 1.5em; margin: 0; margin-bottom: 0.5em; text-align: justify; orphans: 2; widows: 2; }
                .chapter { page-break-after: always; }
            </style>
        </head>
        <body>

        """
    }

    private func generateKDPChapter(_ chapter: Chapter) -> String {
        let formattedContent = formatChapterContent(chapter.content)
        return """
        <div class="chapter">
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

    private func generateKDPFooter() -> String {
        return """
        </body>
        </html>
        """
    }

    // MARK: - Parsing

    private func parseKDPChapters(from content: String) -> [Chapter] {
        var chapters: [Chapter] = []
        let pattern = #"<h1>(.*?)</h1>.*?<p>(.*?)</p>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) else { return chapters }
        let nsContent = content as NSString
        regex.enumerateMatches(in: content, range: NSRange(location: 0, length: content.count)) { match, _, _ in
            guard let match = match else { return }
            let title = nsContent.substring(with: match.range(at: 1))
            let chapterContent = nsContent.substring(with: match.range(at: 2))
                .replacingOccurrences(of: "</p><p>", with: "\n")
            chapters.append(Chapter(title: title, content: chapterContent))
        }
        return chapters
    }

    private func parseKDPMetadata(from content: String) -> BookMetadata {
        var metadata = BookMetadata()
        if let titleRange = content.range(of: #"<title>(.*?)</title>"#, options: .regularExpression) {
            metadata.title = String(content[titleRange])
                .replacingOccurrences(of: "<title>", with: "")
                .replacingOccurrences(of: "</title>", with: "")
        }
        return metadata
    }

    // MARK: - Validation

    func validateForKDP(_ document: EbookDocument) -> [KDPValidationError] {
        Logger.info("Validating document for KDP requirements", category: .conversion)
        var errors: [KDPValidationError] = []

        if document.metadata.title.isEmpty { errors.append(.missingMetadata(field: "title")) }
        if document.metadata.author.isEmpty { errors.append(.missingMetadata(field: "author")) }
        if document.chapters.isEmpty { errors.append(.emptyContent) }

        for (index, chapter) in document.chapters.enumerated() {
            if chapter.title.isEmpty { errors.append(.emptyChapterTitle(chapterIndex: index)) }
            if chapter.content.isEmpty { errors.append(.emptyChapterContent(chapterIndex: index)) }
            let size = chapter.content.utf8.count
            if size > 650_000 { errors.append(.chapterTooLarge(chapterIndex: index, size: size)) }
            let combined = chapter.title + chapter.content
            if combined.unicodeScalars.contains(where: { $0.value > 127 && !isCommonUnicodeCharacter($0) }) {
                errors.append(.uncommonCharacters(chapterIndex: index))
            }
        }

        let totalSize = document.chapters.reduce(0) { $0 + $1.content.utf8.count }
        if totalSize > 50_000_000 { errors.append(.documentTooLarge(size: totalSize)) }

        if errors.isEmpty {
            Logger.info("Document passed all KDP validation checks", category: .conversion)
        } else {
            Logger.warning("Document has \(errors.count) KDP validation issues", category: .conversion)
        }
        return errors
    }

    private func isCommonUnicodeCharacter(_ scalar: Unicode.Scalar) -> Bool {
        let commonRanges: [ClosedRange<UInt32>] = [0x2000...0x206F, 0x2010...0x2027, 0x00A0...0x00FF]
        return commonRanges.contains(where: { $0.contains(scalar.value) })
    }

    // MARK: - Converter Protocol

    func convert(from source: EbookFormat, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            completion(true)
        }
    }
}

// MARK: - Validation Errors

enum KDPValidationError: Error, CustomStringConvertible {
    case missingMetadata(field: String)
    case emptyContent
    case emptyChapterTitle(chapterIndex: Int)
    case emptyChapterContent(chapterIndex: Int)
    case chapterTooLarge(chapterIndex: Int, size: Int)
    case documentTooLarge(size: Int)
    case uncommonCharacters(chapterIndex: Int)
    case invalidHTML(details: String)

    var description: String {
        switch self {
        case .missingMetadata(let f): return "Missing required metadata: \(f)"
        case .emptyContent: return "Document has no chapters"
        case .emptyChapterTitle(let i): return "Chapter \(i + 1) has no title"
        case .emptyChapterContent(let i): return "Chapter \(i + 1) has no content"
        case .chapterTooLarge(let i, let s): return "Chapter \(i + 1) is too large (\(s) bytes). KDP recommends under 650KB"
        case .documentTooLarge(let s): return "Document is very large (\(s) bytes). Consider splitting into smaller files"
        case .uncommonCharacters(let i): return "Chapter \(i + 1) contains uncommon Unicode that may not render on all Kindle devices"
        case .invalidHTML(let d): return "Invalid HTML: \(d)"
        }
    }
}

enum ConversionError: Error {
    case invalidData
    case parsingFailed
    case unsupportedFormat
}
