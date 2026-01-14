import Foundation
import AppKit

/// Unified export validation and error reporting system
class ExportValidator {

    // MARK: - Validation

    /// Validates a document for the specified export format
    /// - Parameters:
    ///   - document: The document to validate
    ///   - format: The target export format (KDP or Google)
    /// - Returns: ValidationReport containing all errors, warnings, and info messages
    func validate(document: EbookDocument, for format: EbookFormat) -> ValidationReport {
        Logger.info("Validating document for \(format.rawValue) export", category: .conversion)

        let report: ValidationReport

        switch format {
        case .kdp:
            report = validateForKDP(document)
        case .google, .epub:
            report = validateForGoogle(document)
        case .pdf:
            report = validateForPDF(document)
        case .mobi, .azw3:
            report = validateForMOBI(document)
        case .unknown:
            report = ValidationReport(format: format, errors: [], warnings: [], info: [])
        }

        Logger.info("Validation complete: \(report.errors.count) errors, \(report.warnings.count) warnings, \(report.info.count) info", category: .conversion)
        return report
    }

    // MARK: - Format-Specific Validation

    private func validateForKDP(_ document: EbookDocument) -> ValidationReport {
        let kdpConverter = KDPConverter()
        let kdpErrors = kdpConverter.validateForKDP(document)

        var errors: [String] = []
        var warnings: [String] = []
        var info: [String] = []

        for error in kdpErrors {
            switch error {
            case .missingMetadata, .emptyContent:
                errors.append(error.description)
            case .chapterTooLarge, .documentTooLarge, .uncommonCharacters:
                warnings.append(error.description)
            case .emptyChapterTitle, .emptyChapterContent:
                warnings.append(error.description)
            case .invalidHTML:
                errors.append(error.description)
            }
        }

        return ValidationReport(format: .kdp, errors: errors, warnings: warnings, info: info)
    }

    private func validateForGoogle(_ document: EbookDocument) -> ValidationReport {
        let googleConverter = GoogleConverter()
        let epubErrors = googleConverter.validateForGooglePlayBooks(document)

        var errors: [String] = []
        var warnings: [String] = []
        var info: [String] = []

        for error in epubErrors {
            switch error.severity {
            case .error:
                errors.append(error.description)
            case .warning:
                warnings.append(error.description)
            case .info:
                info.append(error.description)
            }
        }

        return ValidationReport(format: .google, errors: errors, warnings: warnings, info: info)
    }

    private func validateForPDF(_ document: EbookDocument) -> ValidationReport {
        var errors: [String] = []
        var warnings: [String] = []
        var info: [String] = []

        // Basic PDF validation
        if document.metadata.title.isEmpty {
            errors.append("Missing required field: title")
        }
        if document.chapters.isEmpty {
            errors.append("Document has no chapters")
        }

        // PDF has fewer restrictions than EPUB/KDP
        info.append("PDF format is flexible and has fewer publishing requirements")

        return ValidationReport(format: .pdf, errors: errors, warnings: warnings, info: info)
    }

    private func validateForMOBI(_ document: EbookDocument) -> ValidationReport {
        var errors: [String] = []
        var warnings: [String] = []
        var info: [String] = []

        // MOBI validation similar to KDP
        if document.metadata.title.isEmpty {
            errors.append("Missing required field: title")
        }
        if document.metadata.author.isEmpty {
            errors.append("Missing required field: author")
        }
        if document.chapters.isEmpty {
            errors.append("Document has no chapters")
        }

        warnings.append("MOBI format is deprecated. Consider using KDP (AZW3) format instead")

        return ValidationReport(format: .mobi, errors: errors, warnings: warnings, info: info)
    }

    // MARK: - User Interface

    /// Presents a validation report to the user in a dialog
    /// - Parameter report: The validation report to display
    /// - Returns: True if user wants to proceed despite warnings/errors, false to cancel
    func presentValidationReport(_ report: ValidationReport) -> Bool {
        if report.isValid {
            // No errors - show success message if there are warnings
            if !report.warnings.isEmpty || !report.info.isEmpty {
                return showValidationDialog(
                    title: "Validation Passed with Notes",
                    message: "Document is ready for export to \(report.format.rawValue).",
                    report: report,
                    allowProceed: true
                )
            }
            return true
        } else {
            // Has errors - ask user if they want to proceed anyway
            return showValidationDialog(
                title: "Validation Issues Found",
                message: "Found \(report.errors.count) critical issue(s) that should be fixed before exporting.",
                report: report,
                allowProceed: true  // Allow proceed but with strong warning
            )
        }
    }

    private func showValidationDialog(title: String, message: String, report: ValidationReport, allowProceed: Bool) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = report.errors.isEmpty ? .informational : .warning

        // Build detailed message
        var details = ""

        if !report.errors.isEmpty {
            details += "❌ Errors:\n"
            for error in report.errors {
                details += "  • \(error)\n"
            }
            details += "\n"
        }

        if !report.warnings.isEmpty {
            details += "⚠️ Warnings:\n"
            for warning in report.warnings {
                details += "  • \(warning)\n"
            }
            details += "\n"
        }

        if !report.info.isEmpty {
            details += "ℹ️ Information:\n"
            for info in report.info {
                details += "  • \(info)\n"
            }
        }

        // Set detailed text
        if !details.isEmpty {
            alert.informativeText += "\n\n" + details
        }

        // Add buttons
        if allowProceed {
            if report.errors.isEmpty {
                alert.addButton(withTitle: "Continue Export")
                alert.addButton(withTitle: "Cancel")
            } else {
                alert.addButton(withTitle: "Fix Issues")
                alert.addButton(withTitle: "Export Anyway")
            }
        } else {
            alert.addButton(withTitle: "OK")
        }

        let response = alert.runModal()

        if allowProceed {
            if report.errors.isEmpty {
                return response == .alertFirstButtonReturn  // Continue Export
            } else {
                return response == .alertSecondButtonReturn  // Export Anyway
            }
        }

        return false
    }

    /// Creates a formatted validation report as a string
    /// - Parameter report: The validation report
    /// - Returns: Formatted string representation
    func formatReport(_ report: ValidationReport) -> String {
        var output = "=== Validation Report for \(report.format.rawValue) Export ===\n\n"

        if report.isValid {
            output += "✅ PASSED: Document meets all requirements\n\n"
        } else {
            output += "❌ FAILED: Document has critical issues\n\n"
        }

        if !report.errors.isEmpty {
            output += "Errors (\(report.errors.count)):\n"
            for (index, error) in report.errors.enumerated() {
                output += "  \(index + 1). \(error)\n"
            }
            output += "\n"
        }

        if !report.warnings.isEmpty {
            output += "Warnings (\(report.warnings.count)):\n"
            for (index, warning) in report.warnings.enumerated() {
                output += "  \(index + 1). \(warning)\n"
            }
            output += "\n"
        }

        if !report.info.isEmpty {
            output += "Information (\(report.info.count)):\n"
            for (index, info) in report.info.enumerated() {
                output += "  \(index + 1). \(info)\n"
            }
            output += "\n"
        }

        return output
    }
}

// MARK: - Validation Report

/// Contains the results of a document validation
struct ValidationReport {
    let format: EbookFormat
    let errors: [String]
    let warnings: [String]
    let info: [String]

    /// Returns true if there are no critical errors
    var isValid: Bool {
        return errors.isEmpty
    }

    /// Returns the total count of all issues
    var totalIssues: Int {
        return errors.count + warnings.count + info.count
    }

    /// Returns a summary string
    var summary: String {
        if isValid {
            if totalIssues == 0 {
                return "Perfect! No issues found."
            } else {
                return "Ready to export with \(warnings.count) warning(s) and \(info.count) note(s)."
            }
        } else {
            return "\(errors.count) critical error(s) must be fixed before exporting."
        }
    }
}
