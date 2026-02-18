import Foundation

/// Unified export validation system — returns structured reports, no UI dependencies
class ExportValidator {

    func validate(document: EbookDocument, for format: EbookFormat) -> ValidationReport {
        Logger.info("Validating document for \(format.rawValue) export", category: .conversion)
        let report: ValidationReport
        switch format {
        case .kdp:          report = validateForKDP(document)
        case .google, .epub: report = validateForGoogle(document)
        case .pdf:          report = validateForPDF(document)
        case .mobi, .azw3:  report = validateForMOBI(document)
        case .unknown:      report = ValidationReport(format: format, errors: [], warnings: [], info: [])
        }
        Logger.info("Validation: \(report.errors.count) errors, \(report.warnings.count) warnings", category: .conversion)
        return report
    }

    private func validateForKDP(_ document: EbookDocument) -> ValidationReport {
        let kdpErrors = KDPConverter().validateForKDP(document)
        var errors: [String] = []
        var warnings: [String] = []
        let info: [String] = []
        for error in kdpErrors {
            switch error {
            case .missingMetadata, .emptyContent, .invalidHTML: errors.append(error.description)
            default: warnings.append(error.description)
            }
        }
        return ValidationReport(format: .kdp, errors: errors, warnings: warnings, info: info)
    }

    private func validateForGoogle(_ document: EbookDocument) -> ValidationReport {
        let epubErrors = GoogleConverter().validateForGooglePlayBooks(document)
        var errors: [String] = []
        var warnings: [String] = []
        var info: [String] = []
        for error in epubErrors {
            switch error.severity {
            case .error: errors.append(error.description)
            case .warning: warnings.append(error.description)
            case .info: info.append(error.description)
            }
        }
        return ValidationReport(format: .google, errors: errors, warnings: warnings, info: info)
    }

    private func validateForPDF(_ document: EbookDocument) -> ValidationReport {
        var errors: [String] = []
        if document.metadata.title.isEmpty { errors.append("Missing required field: title") }
        if document.chapters.isEmpty { errors.append("Document has no chapters") }
        return ValidationReport(format: .pdf, errors: errors, warnings: [],
                                info: ["PDF format has fewer publishing requirements"])
    }

    private func validateForMOBI(_ document: EbookDocument) -> ValidationReport {
        var errors: [String] = []
        if document.metadata.title.isEmpty { errors.append("Missing required field: title") }
        if document.metadata.author.isEmpty { errors.append("Missing required field: author") }
        if document.chapters.isEmpty { errors.append("Document has no chapters") }
        return ValidationReport(format: .mobi, errors: errors,
                                warnings: ["MOBI format is deprecated. Consider using KDP (AZW3) instead"],
                                info: [])
    }
}

// MARK: - Validation Report

struct ValidationReport {
    let format: EbookFormat
    let errors: [String]
    let warnings: [String]
    let info: [String]

    var isValid: Bool { errors.isEmpty }
    var totalIssues: Int { errors.count + warnings.count + info.count }

    var summary: String {
        if isValid {
            return totalIssues == 0
                ? "No issues found. Ready to export."
                : "Ready to export with \(warnings.count) warning(s)."
        } else {
            return "\(errors.count) error(s) must be fixed before exporting."
        }
    }
}
