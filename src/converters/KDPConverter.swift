import Foundation

class KDPConverter: Converter {

    // MARK: - Async/Await API

    /// Asynchronously converts an EbookDocument to KDP format
    /// - Parameter document: The document to convert
    /// - Returns: KDP-formatted data
    /// - Throws: ConversionError if conversion fails
    func convertToKDP(document: EbookDocument) async throws -> Data {
        Logger.info("Starting KDP conversion for document: \(document.metadata.title)", category: .conversion)

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let data = try convertToKDPSync(document: document)
                    Logger.info("KDP conversion completed successfully. Size: \(data.count) bytes", category: .conversion)
                    continuation.resume(returning: data)
                } catch {
                    Logger.error("KDP conversion failed", error: error, category: .conversion)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Synchronous Implementation

    private func convertToKDPSync(document: EbookDocument) throws -> Data {
        // Implementation for converting EbookDocument to .kdp format
        // Note: FormattingEngine currently unused, but available via ServiceContainer if needed
        // let formattingEngine = ServiceContainer.shared.resolve(FormattingEngine.self) ?? FormattingEngine()

        // Validate document before conversion
        guard !document.chapters.isEmpty else {
            Logger.warning("KDP conversion attempted on document with no chapters", category: .conversion)
            throw ConversionError.invalidData
        }

        Logger.debug("Converting \(document.chapters.count) chapters to KDP format", category: .conversion)

        // Optimize formatting for KDP
        let optimizedContent = optimizeDocumentForKDP(document)

        // Generate KDP-formatted content
        var kdpContent = generateKDPHeader(document.metadata)

        for chapter in optimizedContent.chapters {
            kdpContent += generateKDPChapter(chapter)
        }

        kdpContent += generateKDPFooter()

        guard let data = kdpContent.data(using: .utf8) else {
            Logger.error("Failed to encode KDP content as UTF-8", error: ConversionError.parsingFailed, category: .conversion)
            throw ConversionError.parsingFailed
        }

        Logger.debug("Generated KDP HTML with \(kdpContent.count) characters", category: .conversion)
        return data
    }
    
    /// Asynchronously converts KDP format data to EbookDocument
    /// - Parameter data: KDP-formatted data
    /// - Returns: Parsed EbookDocument
    /// - Throws: ConversionError if parsing fails
    func convertFromKDP(data: Data) async throws -> EbookDocument {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let document = try convertFromKDPSync(data: data)
                    continuation.resume(returning: document)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func convertFromKDPSync(data: Data) throws -> EbookDocument {
        // Implementation for converting from .kdp format to EbookDocument
        guard let content = String(data: data, encoding: .utf8) else {
            throw ConversionError.invalidData
        }

        let document = EbookDocument()
        document.chapters = parseKDPChapters(from: content)
        document.metadata = parseKDPMetadata(from: content)

        return document
    }
    
    private func optimizeDocumentForKDP(_ document: EbookDocument) -> EbookDocument {
        let optimizedDocument = document
        
        // Apply KDP-specific formatting rules
        optimizedDocument.formatting.fontSize = 12
        optimizedDocument.formatting.fontName = "Times New Roman"
        optimizedDocument.formatting.lineSpacing = 1.15
        optimizedDocument.formatting.chapterStartsNewPage = true
        
        return optimizedDocument
    }
    
    private func generateKDPHeader(_ metadata: BookMetadata) -> String {
        let title = escapeHTML(metadata.title)
        let author = escapeHTML(metadata.author)
        let description = escapeHTML(metadata.description)

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="\(metadata.language)">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            <title>\(title)</title>
            <meta name="author" content="\(author)"/>
            <meta name="description" content="\(description)"/>
            <meta name="publisher" content="\(escapeHTML(metadata.publisher))"/>
            <meta name="generator" content="Avant Garde Ebook Authoring Tool"/>
            <style type="text/css">
                /* KDP-optimized styles */
                body {
                    font-family: 'Times New Roman', serif;
                    font-size: 12pt;
                    line-height: 1.15;
                    margin: 2em;
                    text-align: justify;
                }
                h1 {
                    font-size: 1.5em;
                    font-weight: bold;
                    text-align: center;
                    page-break-before: always;
                    margin: 1em 0;
                }
                p {
                    text-indent: 1.5em;
                    margin: 0;
                    margin-bottom: 0.5em;
                    text-align: justify;
                }
                .chapter {
                    page-break-after: always;
                }
                /* Prevent widows and orphans */
                p {
                    orphans: 2;
                    widows: 2;
                }
            </style>
        </head>
        <body>

        """
    }
    
    private func generateKDPChapter(_ chapter: Chapter) -> String {
        let title = escapeHTML(chapter.title)
        let formattedContent = formatChapterContentForKDP(chapter.content)

        return """
        <div class="chapter">
            <h1>\(title)</h1>
\(formattedContent)
        </div>

        """
    }

    private func formatChapterContentForKDP(_ content: String) -> String {
        // Split content into paragraphs (double newlines separate paragraphs)
        let paragraphs = content.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Format each paragraph with proper HTML
        let formattedParagraphs = paragraphs.map { paragraph -> String in
            let escapedParagraph = escapeHTML(paragraph)
            // Replace single newlines within paragraphs with <br/> tags
            let withBreaks = escapedParagraph.replacingOccurrences(of: "\n", with: "<br/>\n")
            return "            <p>\(withBreaks)</p>"
        }

        return formattedParagraphs.joined(separator: "\n")
    }

    private func escapeHTML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
    
    private func generateKDPFooter() -> String {
        return """
        </body>
        </html>
        """
    }
    
    private func parseKDPChapters(from content: String) -> [Chapter] {
        // Parse chapters from KDP content
        var chapters: [Chapter] = []
        
        // Simple regex-based parsing (in real implementation, use proper XML parser)
        let chapterPattern = #"<h1>(.*?)</h1>.*?<p>(.*?)</p>"#
        let regex = try? NSRegularExpression(pattern: chapterPattern, options: .dotMatchesLineSeparators)
        
        let nsContent = content as NSString
        regex?.enumerateMatches(in: content, range: NSRange(location: 0, length: content.count)) { match, _, _ in
            guard let match = match else { return }
            
            let titleRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            
            let title = nsContent.substring(with: titleRange)
            let chapterContent = nsContent.substring(with: contentRange)
                .replacingOccurrences(of: "</p><p>", with: "\n")
            
            chapters.append(Chapter(title: title, content: chapterContent))
        }
        
        return chapters
    }
    
    private func parseKDPMetadata(from content: String) -> BookMetadata {
        var metadata = BookMetadata()

        // Parse metadata from KDP content
        if let titleMatch = content.range(of: #"<title>(.*?)</title>"#, options: .regularExpression) {
            metadata.title = String(content[titleMatch])
                .replacingOccurrences(of: "<title>", with: "")
                .replacingOccurrences(of: "</title>", with: "")
        }

        return metadata
    }

    // MARK: - KDP Validation

    /// Validates a document against KDP (Kindle Direct Publishing) requirements
    /// - Parameter document: The document to validate
    /// - Returns: Array of validation errors (empty if valid)
    func validateForKDP(_ document: EbookDocument) -> [KDPValidationError] {
        Logger.info("Validating document for KDP requirements", category: .conversion)
        var errors: [KDPValidationError] = []

        // Check metadata requirements
        if document.metadata.title.isEmpty {
            errors.append(.missingMetadata(field: "title"))
        }
        if document.metadata.author.isEmpty {
            errors.append(.missingMetadata(field: "author"))
        }

        // Check content requirements
        if document.chapters.isEmpty {
            errors.append(.emptyContent)
        }

        // Validate each chapter
        for (index, chapter) in document.chapters.enumerated() {
            if chapter.title.isEmpty {
                errors.append(.emptyChapterTitle(chapterIndex: index))
            }
            if chapter.content.isEmpty {
                errors.append(.emptyChapterContent(chapterIndex: index))
            }

            // Check for excessively long chapters (KDP recommends <650KB per HTML file)
            let estimatedSize = chapter.content.utf8.count
            if estimatedSize > 650_000 {
                errors.append(.chapterTooLarge(chapterIndex: index, size: estimatedSize))
            }
        }

        // Validate total document size (KDP allows up to 650MB, but warn at 50MB)
        let totalSize = document.chapters.reduce(0) { $0 + $1.content.utf8.count }
        if totalSize > 50_000_000 {
            errors.append(.documentTooLarge(size: totalSize))
        }

        // Check for potentially problematic content
        for (index, chapter) in document.chapters.enumerated() {
            // Warn about non-ASCII characters that might not render properly
            let content = chapter.title + chapter.content
            if content.unicodeScalars.contains(where: { $0.value > 127 && !isCommonUnicodeCharacter($0) }) {
                errors.append(.uncommonCharacters(chapterIndex: index))
            }
        }

        if errors.isEmpty {
            Logger.info("Document passed all KDP validation checks", category: .conversion)
        } else {
            Logger.warning("Document has \(errors.count) KDP validation errors", category: .conversion)
        }

        return errors
    }

    private func isCommonUnicodeCharacter(_ scalar: Unicode.Scalar) -> Bool {
        // Allow common extended characters (smart quotes, em dashes, etc.)
        let commonRanges: [ClosedRange<UInt32>] = [
            0x2000...0x206F,  // General Punctuation
            0x2010...0x2027,  // Dashes, quotes
            0x00A0...0x00FF   // Latin-1 Supplement
        ]
        return commonRanges.contains(where: { $0.contains(scalar.value) })
    }

    // MARK: - Converter Protocol

    func convert(from source: EbookFormat, completion: @escaping (Bool) -> Void) {
        // This is a simplified conversion that would need a document parameter in a real implementation
        // For now, just simulate conversion success
        DispatchQueue.global(qos: .userInitiated).async {
            // Simulate conversion work
            Thread.sleep(forTimeInterval: 0.5)
            completion(true)
        }
    }
}

// MARK: - KDP Validation Errors

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
        case .missingMetadata(let field):
            return "Missing required metadata field: \(field)"
        case .emptyContent:
            return "Document has no chapters"
        case .emptyChapterTitle(let index):
            return "Chapter \(index + 1) has no title"
        case .emptyChapterContent(let index):
            return "Chapter \(index + 1) has no content"
        case .chapterTooLarge(let index, let size):
            return "Chapter \(index + 1) is too large (\(size) bytes). KDP recommends chapters under 650KB"
        case .documentTooLarge(let size):
            return "Document is very large (\(size) bytes). Consider splitting into smaller files"
        case .uncommonCharacters(let index):
            return "Chapter \(index + 1) contains uncommon Unicode characters that may not render properly on all Kindle devices"
        case .invalidHTML(let details):
            return "Invalid HTML: \(details)"
        }
    }
}

enum ConversionError: Error {
    case invalidData
    case parsingFailed
    case unsupportedFormat
}