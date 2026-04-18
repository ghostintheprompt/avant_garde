import Foundation

class KDPConverter: Converter {

    private let engine = FormattingEngine.shared

    // MARK: - Async API

    func convertToKDP(document: EbookDocument) async throws -> Data {
        Logger.info("Starting professional KDP conversion for: \(document.metadata.title)", category: .conversion)
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

        let preset = document.metadata.preset
        Logger.debug("Converting \(document.chapters.count) chapters using '\(preset.rawValue)' layout engine", category: .conversion)

        var html = generateHeader(document.metadata)
        for (index, chapter) in document.chapters.enumerated() {
            html += engine.formatChapter(chapter, metadata: document.metadata, index: index)
        }
        html += generateFooter()

        guard let data = html.data(using: .utf8) else {
            throw ConversionError.parsingFailed
        }

        Logger.info("Professional KDP conversion completed. Size: \(data.count) bytes", category: .conversion)
        return data
    }

    private func convertFromKDPSync(data: Data) throws -> EbookDocument {
        throw ConversionError.unsupportedFormat
    }

    // MARK: - HTML Generation

    private func generateHeader(_ metadata: BookMetadata) -> String {
        let css = engine.generateCSS(for: metadata)
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="\(metadata.language)">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            <title>\(metadata.title.htmlEscaped)</title>
            <meta name="author" content="\(metadata.author.htmlEscaped)"/>
            <meta name="generator" content="Avant Garde Professional Layout Engine"/>
            <style type="text/css">
        \(css)
            </style>
        </head>
        <body>
        """
    }

    private func generateFooter() -> String {
        return """
        </body>
        </html>
        """
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
        }

        return errors
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
