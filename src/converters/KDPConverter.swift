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
        let formattingEngine = FormattingEngine()

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
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <title>\(metadata.title)</title>
            <meta name="author" content="\(metadata.author)"/>
            <meta name="description" content="\(metadata.description)"/>
        </head>
        <body>
        
        """
    }
    
    private func generateKDPChapter(_ chapter: Chapter) -> String {
        return """
        <div class="chapter">
            <h1>\(chapter.title)</h1>
            <p>\(chapter.content.replacingOccurrences(of: "\n", with: "</p><p>"))</p>
        </div>
        
        """
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

enum ConversionError: Error {
    case invalidData
    case parsingFailed
    case unsupportedFormat
}