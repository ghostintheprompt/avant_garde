import Foundation
#if canImport(AppKit)
import AppKit
#endif

// ValidationSeverity and ValidationError are defined here (single canonical source)
enum ValidationSeverity {
    case error
    case warning
    case info
}

struct ValidationError {
    let message: String
    let severity: ValidationSeverity
    let location: NSRange?
}

enum PublishingPlatform {
    case kdp
    case google
    case generic
}

class FormattingEngine {

    // MARK: - Platform Validation (cross-platform: operates on String content)

    func validateForPlatform(_ platform: PublishingPlatform, text: NSAttributedString) -> [ValidationError] {
        switch platform {
        case .kdp: return validateKDPRequirements(text)
        case .google: return validateGoogleRequirements(text)
        case .generic: return validateGenericRequirements(text)
        }
    }

    private func validateKDPRequirements(_ text: NSAttributedString) -> [ValidationError] {
        var errors: [ValidationError] = []
        let textString = text.string

        if textString.count > 650_000 {
            errors.append(ValidationError(
                message: "Text exceeds KDP's recommended length of 650,000 characters",
                severity: .warning, location: nil
            ))
        }
        if !textString.contains("Chapter") && textString.count > 10_000 {
            errors.append(ValidationError(
                message: "Long text without chapter breaks may not format well in KDP",
                severity: .warning, location: nil
            ))
        }

        #if canImport(AppKit)
        // Font validation — AppKit only (NSFont not available on iOS)
        text.enumerateAttribute(.font, in: NSRange(location: 0, length: text.length)) { font, range, _ in
            if let nsFont = font as? NSFont {
                let supportedFonts = ["Times New Roman", "Arial", "Helvetica", "Calibri"]
                if !supportedFonts.contains(where: { nsFont.fontName.contains($0) }) {
                    errors.append(ValidationError(
                        message: "Font '\(nsFont.fontName)' may not be supported by KDP",
                        severity: .warning, location: range
                    ))
                }
            }
        }
        #endif // canImport(AppKit)

        return errors
    }

    private func validateGoogleRequirements(_ text: NSAttributedString) -> [ValidationError] {
        var errors: [ValidationError] = []
        let textString = text.string

        if textString.count > 2_000_000 {
            errors.append(ValidationError(
                message: "Text exceeds Google's recommended length",
                severity: .error, location: nil
            ))
        }
        if textString.contains("<script>") {
            errors.append(ValidationError(
                message: "Script tags are not allowed in Google Play Books",
                severity: .error, location: nil
            ))
        }
        return errors
    }

    private func validateGenericRequirements(_ text: NSAttributedString) -> [ValidationError] {
        var errors: [ValidationError] = []
        if text.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                message: "Document appears to be empty",
                severity: .error, location: nil
            ))
        }
        return errors
    }

    // MARK: - Format Conversion (operates on NSAttributedString, cross-platform)

    func convertFormatting(from: EbookFormat, to: EbookFormat, text: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: text)
        switch (from, to) {
        case (.kdp, .epub): return adjustParagraphStyle(mutable, firstIndent: 20, paraSpacing: 12)
        case (.epub, .kdp), (.google, .kdp): return adjustParagraphStyle(mutable, lineSpacing: 1.5, paraSpacing: 6)
        case (.kdp, .google): return adjustParagraphStyle(mutable, firstIndent: 20, paraSpacing: 12)
        default: return mutable
        }
    }

    private func adjustParagraphStyle(
        _ text: NSMutableAttributedString,
        firstIndent: CGFloat = 0,
        lineSpacing: CGFloat = 0,
        paraSpacing: CGFloat = 0
    ) -> NSAttributedString {
        let range = NSRange(location: 0, length: text.length)
        let style = NSMutableParagraphStyle()
        if firstIndent > 0 { style.firstLineHeadIndent = firstIndent }
        if lineSpacing > 0 { style.lineSpacing = lineSpacing }
        if paraSpacing > 0 { style.paragraphSpacing = paraSpacing }
        text.addAttribute(.paragraphStyle, value: style, range: range)
        return text
    }
}
