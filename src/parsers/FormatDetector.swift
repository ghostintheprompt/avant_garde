class FormatDetector {
    enum DetectionError: Error {
        case unsupportedFormat
    }

    func detectFormat(of filePath: String) throws -> EbookFormat {
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
        default:
            throw DetectionError.unsupportedFormat
        }
    }
}