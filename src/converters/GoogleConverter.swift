import Foundation

class GoogleConverter: Converter {

    // MARK: - Async/Await API

    /// Asynchronously converts an EbookDocument to Google Play Books format (EPUB)
    /// - Parameter document: The document to convert
    /// - Returns: EPUB-formatted data
    /// - Throws: ConversionError if conversion fails
    func convertToGoogle(document: EbookDocument) async throws -> Data {
        Logger.info("Starting Google Play Books EPUB conversion for: \(document.metadata.title)", category: .conversion)

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let data = try convertToGoogleSync(document: document)
                    Logger.info("Google EPUB conversion completed successfully. Size: \(data.count) bytes", category: .conversion)
                    continuation.resume(returning: data)
                } catch {
                    Logger.error("Google EPUB conversion failed", error: error, category: .conversion)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Asynchronously converts Google/EPUB format data to EbookDocument
    /// - Parameter data: EPUB-formatted data
    /// - Returns: Parsed EbookDocument
    /// - Throws: ConversionError if parsing fails
    func convertFromGoogle(data: Data) async throws -> EbookDocument {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let document = try convertFromGoogleSync(data: data)
                    continuation.resume(returning: document)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Synchronous Implementation

    private func convertToGoogleSync(document: EbookDocument) throws -> Data {
        // Implementation for converting EbookDocument to Google Play Books format (EPUB)
        // Note: FormattingEngine currently unused, but available via ServiceContainer if needed
        // let formattingEngine = ServiceContainer.shared.resolve(FormattingEngine.self) ?? FormattingEngine()

        Logger.debug("Optimizing document for Google Play Books format", category: .conversion)

        // Optimize formatting for Google Play Books
        let optimizedDocument = optimizeDocumentForGoogle(document)

        // Generate EPUB content for Google Play Books
        Logger.debug("Generating EPUB with \(optimizedDocument.chapters.count) chapters", category: .conversion)
        let epubContent = generateGoogleEPUB(optimizedDocument)

        guard let data = epubContent.data(using: .utf8), !data.isEmpty else {
            Logger.error("Failed to generate EPUB data", error: ConversionError.parsingFailed, category: .conversion)
            throw ConversionError.parsingFailed
        }

        Logger.debug("Generated EPUB with \(epubContent.count) characters", category: .conversion)
        return data
    }

    private func convertFromGoogleSync(data: Data) throws -> EbookDocument {
        // Implementation for converting from Google format to EbookDocument
        guard let content = String(data: data, encoding: .utf8) else {
            throw ConversionError.invalidData
        }
        
        let document = EbookDocument()
        document.chapters = parseGoogleChapters(from: content)
        document.metadata = parseGoogleMetadata(from: content)
        
        return document
    }
    
    private func optimizeDocumentForGoogle(_ document: EbookDocument) -> EbookDocument {
        let optimizedDocument = document
        
        // Apply Google Play Books-specific formatting rules
        optimizedDocument.formatting.fontSize = 11
        optimizedDocument.formatting.fontName = "Arial"
        optimizedDocument.formatting.lineSpacing = 1.2
        optimizedDocument.formatting.chapterStartsNewPage = true
        
        return optimizedDocument
    }
    
    private func generateGoogleEPUB(_ document: EbookDocument) -> String {
        var epubContent = generateEPUBHeader(document.metadata)
        
        // Generate table of contents
        epubContent += generateTableOfContents(document.chapters)
        
        // Generate chapters
        for chapter in document.chapters {
            epubContent += generateEPUBChapter(chapter)
        }
        
        epubContent += generateEPUBFooter()
        
        return epubContent
    }
    
    private func generateEPUBHeader(_ metadata: BookMetadata) -> String {
        let title = escapeHTML(metadata.title)
        let author = escapeHTML(metadata.author)
        let description = escapeHTML(metadata.description)
        let publisher = escapeHTML(metadata.publisher)
        let isbn = escapeHTML(metadata.isbn)
        let rights = escapeHTML(metadata.rights)

        // Generate unique identifier if not provided
        let identifier = metadata.isbn.isEmpty ?
            "urn:uuid:\(UUID().uuidString)" :
            "urn:isbn:\(isbn)"

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="\(metadata.language)">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            <title>\(title)</title>
            <!-- Dublin Core Metadata -->
            <meta name="dc:title" content="\(title)"/>
            <meta name="dc:creator" content="\(author)"/>
            <meta name="dc:publisher" content="\(publisher)"/>
            <meta name="dc:identifier" content="\(identifier)"/>
            <meta name="dc:language" content="\(metadata.language)"/>
            <meta name="dc:rights" content="\(rights)"/>
            <meta name="dc:date" content="\(metadata.publicationDate)"/>
            <meta name="dc:description" content="\(description)"/>
            <!-- Standard Metadata -->
            <meta name="author" content="\(author)"/>
            <meta name="description" content="\(description)"/>
            <meta name="generator" content="Avant Garde Ebook Authoring Tool"/>
            <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
            <style type="text/css">
                /* Google Play Books optimized styles */
                body {
                    font-family: Arial, 'Helvetica Neue', sans-serif;
                    font-size: 11pt;
                    line-height: 1.2;
                    margin: 1.5em;
                    text-align: justify;
                }
                h1 {
                    font-size: 1.5em;
                    font-weight: bold;
                    text-align: center;
                    page-break-before: always;
                    margin: 1.5em 0;
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
                .toc {
                    page-break-after: always;
                }
                .toc h1 {
                    page-break-before: avoid;
                }
                .toc ul {
                    list-style-type: none;
                    padding-left: 0;
                }
                .toc li {
                    margin: 0.5em 0;
                }
                /* Prevent widows and orphans */
                p {
                    orphans: 2;
                    widows: 2;
                }
                /* Responsive images */
                img {
                    max-width: 100%;
                    height: auto;
                }
            </style>
        </head>
        <body>

        """
    }

    private func escapeHTML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
    
    private func generateTableOfContents(_ chapters: [Chapter]) -> String {
        var toc = """
        <div class="toc">
            <h1>Table of Contents</h1>
            <ul>
        
        """
        
        for (index, chapter) in chapters.enumerated() {
            toc += """
                <li><a href="#chapter\(index + 1)">\(chapter.title)</a></li>
        
            """
        }
        
        toc += """
            </ul>
        </div>
        
        """
        
        return toc
    }
    
    private func generateEPUBChapter(_ chapter: Chapter) -> String {
        let chapterIndex = chapter.id.uuidString
        let title = escapeHTML(chapter.title)
        let formattedContent = formatChapterContent(chapter.content)

        return """
        <div class="chapter" id="chapter\(chapterIndex)">
            <h1>\(title)</h1>
\(formattedContent)
        </div>

        """
    }

    private func formatChapterContent(_ content: String) -> String {
        // Split content into paragraphs (double newlines separate paragraphs)
        let paragraphs = content.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Format each paragraph with proper HTML escaping
        let formattedParagraphs = paragraphs.map { paragraph -> String in
            let escapedParagraph = escapeHTML(paragraph)
            // Replace single newlines within paragraphs with <br/> tags
            let withBreaks = escapedParagraph.replacingOccurrences(of: "\n", with: "<br/>\n")
            return "            <p>\(withBreaks)</p>"
        }

        return formattedParagraphs.joined(separator: "\n")
    }
    
    private func generateEPUBFooter() -> String {
        return """
        </body>
        </html>
        """
    }
    
    private func parseGoogleChapters(from content: String) -> [Chapter] {
        var chapters: [Chapter] = []
        
        // Parse chapters from Google/EPUB content
        let chapterPattern = #"<h1[^>]*>(.*?)</h1>(.*?)(?=<h1|</body>)"#
        let regex = try? NSRegularExpression(pattern: chapterPattern, options: .dotMatchesLineSeparators)
        
        let nsContent = content as NSString
        regex?.enumerateMatches(in: content, range: NSRange(location: 0, length: content.count)) { match, _, _ in
            guard let match = match else { return }
            
            let titleRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            
            let title = nsContent.substring(with: titleRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let chapterContent = nsContent.substring(with: contentRange)
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
        
        // Parse metadata from Google/EPUB content
        if let titleRange = content.range(of: #"<title>(.*?)</title>"#, options: .regularExpression) {
            let titleContent = String(content[titleRange])
            metadata.title = titleContent
                .replacingOccurrences(of: "<title>", with: "")
                .replacingOccurrences(of: "</title>", with: "")
        }
        
        if let authorRange = content.range(of: #"name="author" content="(.*?)""#, options: .regularExpression) {
            let authorContent = String(content[authorRange])
            metadata.author = authorContent
                .replacingOccurrences(of: #"name="author" content=""#, with: "")
                .replacingOccurrences(of: "\"", with: "")
        }
        
        return metadata
    }
    
    // MARK: - Google Play Books Specific Features

    /// Validates a document against Google Play Books requirements
    /// - Parameter document: The document to validate
    /// - Returns: Array of validation errors (empty if valid)
    func validateForGooglePlayBooks(_ document: EbookDocument) -> [EPUBValidationError] {
        Logger.info("Validating document for Google Play Books requirements", category: .conversion)
        var errors: [EPUBValidationError] = []

        // Check required metadata
        if document.metadata.title.isEmpty {
            errors.append(.missingMetadata(field: "title"))
        }
        if document.metadata.author.isEmpty {
            errors.append(.missingMetadata(field: "author"))
        }
        if document.metadata.language.isEmpty {
            errors.append(.missingMetadata(field: "language"))
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

            // Check chapter size (Google recommends <300KB per HTML file)
            let estimatedSize = chapter.content.utf8.count
            if estimatedSize > 300_000 {
                errors.append(.chapterTooLarge(chapterIndex: index, size: estimatedSize))
            }
        }

        // Validate total EPUB size (Google allows up to 100MB)
        let totalSize = document.chapters.reduce(0) { $0 + $1.content.utf8.count }
        if totalSize > 100_000_000 {
            errors.append(.epubTooLarge(size: totalSize))
        } else if totalSize > 50_000_000 {
            // Warning for files over 50MB
            errors.append(.epubLarge(size: totalSize))
        }

        // Check for potentially problematic content
        for (index, chapter) in document.chapters.enumerated() {
            let content = chapter.title + chapter.content

            // Check for HTML tags that might cause issues
            if content.contains("<script") || content.contains("<iframe") {
                errors.append(.unsafeHTML(chapterIndex: index))
            }

            // Warn about excessive special characters
            let specialCharCount = content.unicodeScalars.filter { $0.value > 127 }.count
            if specialCharCount > content.count / 10 {  // More than 10% special characters
                errors.append(.excessiveSpecialCharacters(chapterIndex: index))
            }
        }

        // Check recommended metadata
        if document.metadata.publisher.isEmpty {
            errors.append(.missingRecommendedMetadata(field: "publisher"))
        }
        if document.metadata.description.isEmpty {
            errors.append(.missingRecommendedMetadata(field: "description"))
        }

        if errors.isEmpty {
            Logger.info("Document passed all Google Play Books validation checks", category: .conversion)
        } else {
            Logger.warning("Document has \(errors.count) Google Play Books validation issues", category: .conversion)
        }

        return errors
    }
    
    func optimizeImagesForGoogle(_ imagePaths: [String]) -> [String] {
        // Optimize images for Google Play Books requirements
        // - Maximum file size: 127MB for entire EPUB
        // - Recommended image resolution: 1600x2400 for covers
        // - Supported formats: JPEG, PNG, GIF, SVG

        // This would implement actual image optimization
        return imagePaths
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
        case .missingMetadata(let field):
            return "Missing required metadata field: \(field)"
        case .missingRecommendedMetadata(let field):
            return "Missing recommended metadata field: \(field) (not critical but improves discoverability)"
        case .emptyContent:
            return "Document has no chapters"
        case .emptyChapterTitle(let index):
            return "Chapter \(index + 1) has no title"
        case .emptyChapterContent(let index):
            return "Chapter \(index + 1) has no content"
        case .chapterTooLarge(let index, let size):
            return "Chapter \(index + 1) is too large (\(size) bytes). Google recommends chapters under 300KB"
        case .epubTooLarge(let size):
            return "EPUB is too large (\(size) bytes). Google Play Books allows up to 100MB"
        case .epubLarge(let size):
            return "EPUB is large (\(size) bytes). Consider splitting into multiple volumes for better reader experience"
        case .unsafeHTML(let index):
            return "Chapter \(index + 1) contains potentially unsafe HTML elements (script, iframe)"
        case .excessiveSpecialCharacters(let index):
            return "Chapter \(index + 1) has many special characters that may not render correctly on all devices"
        case .invalidXHTML(let details):
            return "Invalid XHTML: \(details)"
        case .missingTableOfContents:
            return "Document should include a table of contents for better navigation"
        }
    }

    var severity: ValidationSeverity {
        switch self {
        case .missingMetadata, .emptyContent, .epubTooLarge, .unsafeHTML, .invalidXHTML:
            return .error
        case .chapterTooLarge, .epubLarge, .excessiveSpecialCharacters, .emptyChapterTitle, .emptyChapterContent:
            return .warning
        case .missingRecommendedMetadata, .missingTableOfContents:
            return .info
        }
    }
}

enum ValidationSeverity {
    case error    // Must fix before publishing
    case warning  // Should fix for best results
    case info     // Nice to have
}