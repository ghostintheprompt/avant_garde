import Foundation
import os.log

/// Centralized logging system for Avant Garde
/// Uses os.log for optimal performance and integration with Console.app
enum Logger {

    // MARK: - Subsystems

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.avantgarde.app"

    private static let conversionLog = OSLog(subsystem: subsystem, category: "Conversion")
    private static let audioLog = OSLog(subsystem: subsystem, category: "Audio")
    private static let editorLog = OSLog(subsystem: subsystem, category: "Editor")
    private static let uiLog = OSLog(subsystem: subsystem, category: "UI")
    private static let generalLog = OSLog(subsystem: subsystem, category: "General")

    // MARK: - Logging Methods

    /// Log conversion-related messages (KDP, Google, EPUB exports)
    static func conversion(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: conversionLog, type: type, message)
    }

    /// Log audio-related messages (TTS, playback, voice settings)
    static func audio(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: audioLog, type: type, message)
    }

    /// Log editor-related messages (text editing, formatting, chapters)
    static func editor(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: editorLog, type: type, message)
    }

    /// Log UI-related messages (theme changes, preferences, windows)
    static func ui(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: uiLog, type: type, message)
    }

    /// Log general application messages
    static func general(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: generalLog, type: type, message)
    }

    // MARK: - Convenience Methods

    /// Log an error with context
    static func error(_ message: String, error: Error, category: LogCategory = .general) {
        let fullMessage = "\(message): \(error.localizedDescription)"
        log(fullMessage, type: .error, category: category)
    }

    /// Log a warning
    static func warning(_ message: String, category: LogCategory = .general) {
        log(message, type: .default, category: category)
    }

    /// Log a debug message (only appears in debug builds)
    static func debug(_ message: String, category: LogCategory = .general) {
        #if DEBUG
        log(message, type: .debug, category: category)
        #endif
    }

    /// Log an info message
    static func info(_ message: String, category: LogCategory = .general) {
        log(message, type: .info, category: category)
    }

    // MARK: - Private Helpers

    private static func log(_ message: String, type: OSLogType, category: LogCategory) {
        switch category {
        case .conversion:
            conversion(message, type: type)
        case .audio:
            audio(message, type: type)
        case .editor:
            editor(message, type: type)
        case .ui:
            ui(message, type: type)
        case .general:
            general(message, type: type)
        }
    }
}

// MARK: - Log Categories

enum LogCategory {
    case conversion
    case audio
    case editor
    case ui
    case general
}

// MARK: - Error Recovery

/// Error recovery strategies for different error types
struct ErrorRecovery {

    /// Attempt to recover from a conversion error
    static func recoverFromConversionError(_ error: Error, documentTitle: String) -> RecoveryAction {
        Logger.error("Conversion failed for document '\(documentTitle)'", error: error, category: .conversion)

        if let conversionError = error as? ConversionError {
            switch conversionError {
            case .invalidData:
                return .showAlert(
                    title: "Invalid Document Data",
                    message: "The document contains invalid data. Please check your content and try again.",
                    recoveryOptions: ["Edit Document", "Cancel"]
                )
            case .parsingFailed:
                return .showAlert(
                    title: "Parsing Failed",
                    message: "Unable to parse the document format. The file may be corrupted.",
                    recoveryOptions: ["Try Again", "Save As Different Format", "Cancel"]
                )
            case .unsupportedFormat:
                return .showAlert(
                    title: "Unsupported Format",
                    message: "This format is not currently supported. Please try a different export format.",
                    recoveryOptions: ["OK"]
                )
            }
        }

        return .showAlert(
            title: "Export Failed",
            message: "An unexpected error occurred: \(error.localizedDescription)",
            recoveryOptions: ["Try Again", "Cancel"]
        )
    }

    /// Attempt to recover from an audio error
    static func recoverFromAudioError(_ error: Error) -> RecoveryAction {
        Logger.error("Audio playback failed", error: error, category: .audio)

        return .showAlert(
            title: "Audio Playback Error",
            message: "Unable to play audio: \(error.localizedDescription)\n\nPlease check your voice settings.",
            recoveryOptions: ["Open Voice Settings", "Cancel"]
        )
    }

    /// Attempt to recover from a document error
    static func recoverFromDocumentError(_ error: Error, operation: String) -> RecoveryAction {
        Logger.error("Document \(operation) failed", error: error, category: .editor)

        return .showAlert(
            title: "Document \(operation.capitalized) Failed",
            message: "Could not \(operation) the document: \(error.localizedDescription)",
            recoveryOptions: ["Try Again", "Cancel"]
        )
    }
}

// MARK: - Recovery Actions

enum RecoveryAction {
    case showAlert(title: String, message: String, recoveryOptions: [String])
    case retry(operation: () -> Void)
    case silent
}
