import AppKit
import Foundation

enum PublishingPlatform {
    case kdp
    case google
    case generic
}

struct ValidationError {
    let message: String
    let severity: ValidationSeverity
    let location: NSRange?
}

enum ValidationSeverity {
    case error
    case warning
    case info
}

class FormattingEngine {
    
    // MARK: - Format Conversion
    
    func convertFormatting(from: EbookFormat, to: EbookFormat, text: NSAttributedString) -> NSAttributedString {
        let mutableText = NSMutableAttributedString(attributedString: text)
        
        switch (from, to) {
        case (.kdp, .epub):
            return convertKDPToEPUB(mutableText)
        case (.epub, .kdp):
            return convertEPUBToKDP(mutableText)
        case (.google, .kdp):
            return convertGoogleToKDP(mutableText)
        case (.kdp, .google):
            return convertKDPToGoogle(mutableText)
        default:
            return mutableText
        }
    }
    
    private func convertKDPToEPUB(_ text: NSMutableAttributedString) -> NSAttributedString {
        // KDP to EPUB conversion rules
        let range = NSRange(location: 0, length: text.length)
        
        // Adjust margins for EPUB standards
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 20
        paragraphStyle.paragraphSpacing = 12
        
        text.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        
        return text
    }
    
    private func convertEPUBToKDP(_ text: NSMutableAttributedString) -> NSAttributedString {
        // EPUB to KDP conversion rules
        let range = NSRange(location: 0, length: text.length)
        
        // KDP prefers specific formatting
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.5
        paragraphStyle.paragraphSpacing = 6
        
        text.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        
        return text
    }
    
    private func convertGoogleToKDP(_ text: NSMutableAttributedString) -> NSAttributedString {
        // Google to KDP specific conversions
        return convertEPUBToKDP(text) // Similar rules apply
    }
    
    private func convertKDPToGoogle(_ text: NSMutableAttributedString) -> NSAttributedString {
        // KDP to Google specific conversions
        return convertKDPToEPUB(text) // Similar rules apply
    }
    
    // MARK: - Platform Validation
    
    func validateForPlatform(_ platform: PublishingPlatform, text: NSAttributedString) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        switch platform {
        case .kdp:
            errors.append(contentsOf: validateKDPRequirements(text))
        case .google:
            errors.append(contentsOf: validateGoogleRequirements(text))
        case .generic:
            errors.append(contentsOf: validateGenericRequirements(text))
        }
        
        return errors
    }
    
    private func validateKDPRequirements(_ text: NSAttributedString) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // KDP specific validation rules
        let textString = text.string
        
        // Check for excessive formatting
        if textString.count > 650000 {
            errors.append(ValidationError(
                message: "Text exceeds KDP's recommended length of 650,000 characters",
                severity: .warning,
                location: nil
            ))
        }
        
        // Check for proper chapter breaks
        if !textString.contains("Chapter") && textString.count > 10000 {
            errors.append(ValidationError(
                message: "Long text without chapter breaks may not format well in KDP",
                severity: .warning,
                location: nil
            ))
        }
        
        // Font validation
        text.enumerateAttribute(.font, in: NSRange(location: 0, length: text.length)) { (font, range, _) in
            if let nsFont = font as? NSFont {
                let supportedFonts = ["Times New Roman", "Arial", "Helvetica", "Calibri"]
                if !supportedFonts.contains(nsFont.fontName) {
                    errors.append(ValidationError(
                        message: "Font '\(nsFont.fontName)' may not be supported by KDP",
                        severity: .warning,
                        location: range
                    ))
                }
            }
        }
        
        return errors
    }
    
    private func validateGoogleRequirements(_ text: NSAttributedString) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Google Play Books specific validation
        let textString = text.string
        
        // Check file size requirements
        if textString.count > 2000000 {
            errors.append(ValidationError(
                message: "Text exceeds Google's recommended length",
                severity: .error,
                location: nil
            ))
        }
        
        // Check for HTML compatibility
        if textString.contains("<script>") {
            errors.append(ValidationError(
                message: "Script tags are not allowed in Google Play Books",
                severity: .error,
                location: nil
            ))
        }
        
        return errors
    }
    
    private func validateGenericRequirements(_ text: NSAttributedString) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // General validation rules
        let textString = text.string
        
        if textString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                message: "Document appears to be empty",
                severity: .error,
                location: nil
            ))
        }
        
        return errors
    }
    
    // MARK: - Formatting Utilities
    
    func optimizeForPlatform(_ platform: PublishingPlatform, text: NSAttributedString) -> NSAttributedString {
        let mutableText = NSMutableAttributedString(attributedString: text)
        
        switch platform {
        case .kdp:
            return optimizeForKDP(mutableText)
        case .google:
            return optimizeForGoogle(mutableText)
        case .generic:
            return mutableText
        }
    }
    
    private func optimizeForKDP(_ text: NSMutableAttributedString) -> NSAttributedString {
        // Apply KDP-specific optimizations
        let range = NSRange(location: 0, length: text.length)
        
        // Set optimal font for KDP
        let kdpFont = NSFont(name: "Times New Roman", size: 12) ?? NSFont.systemFont(ofSize: 12)
        text.addAttribute(.font, value: kdpFont, range: range)
        
        // Optimize paragraph spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.15
        paragraphStyle.paragraphSpacing = 6
        text.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        
        return text
    }
    
    private func optimizeForGoogle(_ text: NSMutableAttributedString) -> NSAttributedString {
        // Apply Google-specific optimizations
        let range = NSRange(location: 0, length: text.length)
        
        // Set optimal font for Google Play Books
        let googleFont = NSFont(name: "Arial", size: 11) ?? NSFont.systemFont(ofSize: 11)
        text.addAttribute(.font, value: googleFont, range: range)
        
        return text
    }
}
