import Foundation

class FormatDetector {
    enum DetectionError: Error {
        case unsupportedFormat
        case fileNotReadable
        case invalidFormat
    }

    /// Detects ebook format using both extension and content-based detection
    func detectFormat(of filePath: String) throws -> EbookFormat {
        Logger.info("Detecting format for: \(filePath)", category: .general)

        // First try content-based detection (most reliable)
        if let contentFormat = try? detectFormatByContent(filePath: filePath) {
            Logger.info("Format detected by content: \(contentFormat.rawValue)", category: .general)
            return contentFormat
        }

        // Fallback to extension-based detection
        let extensionFormat = detectFormatByExtension(filePath: filePath)
        if extensionFormat != .unknown {
            Logger.info("Format detected by extension: \(extensionFormat.rawValue)", category: .general)
            return extensionFormat
        }

        Logger.warning("Unable to detect format for: \(filePath)", category: .general)
        throw DetectionError.unsupportedFormat
    }

    // MARK: - Extension-Based Detection

    private func detectFormatByExtension(filePath: String) -> EbookFormat {
        let fileExtension = (filePath as NSString).pathExtension.lowercased()

        switch fileExtension {
        case "kdp":
            return .kdp
        case "epub":
            return .epub
        case "pdf":
            return .pdf
        case "mobi":
            return .mobi
        case "azw3", "azw":
            return .azw3
        default:
            return .unknown
        }
    }

    // MARK: - Content-Based Detection (Magic Numbers)

    private func detectFormatByContent(filePath: String) throws -> EbookFormat {
        let url = URL(fileURLWithPath: filePath)

        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            throw DetectionError.fileNotReadable
        }

        defer {
            try? fileHandle.close()
        }

        // Read first 512 bytes for magic number detection
        let headerData = fileHandle.readData(ofLength: 512)
        guard headerData.count > 0 else {
            throw DetectionError.invalidFormat
        }

        // Check for PDF magic number: "%PDF-"
        if isPDF(headerData) {
            return .pdf
        }

        // Check for EPUB magic number: ZIP signature + mimetype check
        if isEPUB(filePath: filePath, headerData: headerData) {
            return .epub
        }

        // Check for MOBI/AZW3 magic numbers
        if let mobiFormat = detectMOBIVariant(headerData: headerData) {
            return mobiFormat
        }

        // Check for KDP format markers (if any specific pattern exists)
        if isKDP(headerData: headerData) {
            return .kdp
        }

        throw DetectionError.unsupportedFormat
    }

    // MARK: - Format-Specific Detection

    private func isPDF(_ data: Data) -> Bool {
        // PDF files start with "%PDF-"
        let pdfMagic = Data([0x25, 0x50, 0x44, 0x46, 0x2D]) // %PDF-
        return data.prefix(5) == pdfMagic
    }

    private func isEPUB(filePath: String, headerData: Data) -> Bool {
        // EPUB is a ZIP archive with specific structure
        // ZIP magic number: PK\x03\x04
        let zipMagic = Data([0x50, 0x4B, 0x03, 0x04]) // PK

        if headerData.prefix(4) != zipMagic {
            return false
        }

        // Additional check: EPUB must contain "mimetype" file with "application/epub+zip"
        // We'll verify this by checking if we can find the mimetype string
        let url = URL(fileURLWithPath: filePath)

        // Try to read the mimetype entry (first file in EPUB)
        if let mimetypeData = try? Data(contentsOf: url).prefix(100),
           let mimetypeString = String(data: mimetypeData, encoding: .ascii) {
            return mimetypeString.contains("application/epub") ||
                   mimetypeString.contains("mimetype")
        }

        // If we can't verify mimetype but it's a ZIP, assume EPUB if extension matches
        return true
    }

    private func detectMOBIVariant(headerData: Data) -> EbookFormat? {
        // MOBI magic number is typically at offset 60
        // Check for "MOBI" or "BOOKMOBI" markers

        if headerData.count < 68 {
            return nil
        }

        // Check at offset 60 for MOBI marker
        let offset60Data = headerData.subdata(in: 60..<min(68, headerData.count))
        if let marker = String(data: offset60Data, encoding: .ascii) {
            if marker.contains("BOOKMOBI") {
                return .mobi
            }
            if marker.contains("MOBI") {
                return .mobi
            }
            if marker.contains("TPZ") {
                // TPZ is Kindle's topaz format, treat as MOBI variant
                return .mobi
            }
        }

        // Check for AZW3 specific markers
        // AZW3 may have different markers or metadata
        if headerData.count >= 100 {
            let extendedData = headerData.prefix(100)
            if let extendedString = String(data: extendedData, encoding: .ascii) {
                if extendedString.contains("EXTH") {
                    // Extended header typically present in AZW3
                    return .azw3
                }
            }
        }

        return nil
    }

    private func isKDP(_ data: Data) -> Bool {
        // KDP format detection
        // Note: KDP might be a custom format or HTML-based
        // Check for common HTML/XML markers that might indicate KDP format

        if let string = String(data: data.prefix(100), encoding: .utf8) {
            // Check for HTML/XML structure
            if string.contains("<!DOCTYPE") ||
               string.contains("<html") ||
               string.contains("<?xml") {
                // Could be KDP HTML format
                // Additional validation could check for KDP-specific metadata
                if string.contains("kdp") || string.contains("KDP") {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Utility Methods

    /// Returns a list of all supported formats
    static func supportedFormats() -> [EbookFormat] {
        return [.kdp, .epub, .pdf, .mobi, .azw3]
    }

    /// Returns a human-readable description of supported formats
    static func supportedFormatsDescription() -> String {
        let formats = supportedFormats().map { $0.rawValue }.joined(separator: ", ")
        return "Supported formats: \(formats)"
    }

    /// Validates if a file exists and is readable
    func validateFile(at filePath: String) -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: filePath) &&
               fileManager.isReadableFile(atPath: filePath)
    }
}