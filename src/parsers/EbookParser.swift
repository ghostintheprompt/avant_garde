import Foundation

class EbookParser {
    private let formatDetector: FormatDetector

    // MARK: - Initialization

    /// Initialize with an optional FormatDetector instance (dependency injection)
    /// - Parameter formatDetector: The FormatDetector instance to use (defaults to ServiceContainer)
    init(formatDetector: FormatDetector? = nil) {
        self.formatDetector = formatDetector ?? ServiceContainer.shared.formatDetector
        Logger.debug("EbookParser initialized with dependency injection", category: .general)
    }

    func parse(filePath: String) -> String {
        // Implementation for parsing the eBook file
        // This is a placeholder for the actual parsing logic
        Logger.info("Parsing ebook file: \(filePath)", category: .general)
        return "Parsed content from \(filePath)"
    }

    func getFormat(filePath: String) -> EbookFormat? {
        // Validate file first
        guard formatDetector.validateFile(at: filePath) else {
            Logger.warning("File not found or not readable: \(filePath)", category: .general)
            return nil
        }

        // Detect format using content-based and extension-based detection
        do {
            let format = try formatDetector.detectFormat(of: filePath)
            Logger.info("Detected format: \(format.rawValue) for file: \(filePath)", category: .general)
            return format
        } catch FormatDetector.DetectionError.unsupportedFormat {
            Logger.warning("Unsupported format for file: \(filePath)", category: .general)
            return .unknown
        } catch {
            Logger.error("Format detection failed", error: error, category: .general)
            return nil
        }
    }

    /// Returns true if the file format is supported
    func isFormatSupported(filePath: String) -> Bool {
        guard let format = getFormat(filePath: filePath) else {
            return false
        }
        return FormatDetector.supportedFormats().contains(format)
    }
}