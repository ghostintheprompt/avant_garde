import Foundation

// ValidationSeverity and ValidationError are used by KDPConverter and GoogleConverter.

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
