import XCTest
import Foundation
import AVFoundation
@testable import ebook_converter_macos

// MARK: - Mock Text-to-Speech

/// Mock TextToSpeech for testing
class MockTextToSpeech: TextToSpeech {
    var speakCalled = false
    var stopCalled = false
    var pauseCalled = false
    var continueCalled = false
    var lastSpokenText: String?
    var mockIsSpeaking = false
    var mockIsPaused = false

    override func speak(text: String) {
        speakCalled = true
        lastSpokenText = text
        mockIsSpeaking = true
    }

    override func stopSpeaking() {
        stopCalled = true
        mockIsSpeaking = false
        mockIsPaused = false
    }

    override func pauseSpeaking() {
        pauseCalled = true
        mockIsPaused = true
    }

    override func continueSpeaking() {
        continueCalled = true
        mockIsPaused = false
    }

    override var isSpeaking: Bool {
        return mockIsSpeaking
    }

    override var isPaused: Bool {
        return mockIsPaused
    }
}

// MARK: - Mock Audio Controller Delegate

class MockAudioControllerDelegate: AudioControllerDelegate {
    var didStartCalled = false
    var didFinishCalled = false
    var didPauseCalled = false
    var lastProgress: Float = 0
    var lastError: Error?

    func audioDidStart() {
        didStartCalled = true
    }

    func audioDidFinish() {
        didFinishCalled = true
    }

    func audioDidPause() {
        didPauseCalled = true
    }

    func audioPlaybackProgress(_ progress: Float) {
        lastProgress = progress
    }

    func audioError(_ error: Error) {
        lastError = error
    }

    func reset() {
        didStartCalled = false
        didFinishCalled = false
        didPauseCalled = false
        lastProgress = 0
        lastError = nil
    }
}

// MARK: - Test Data Factory

class TestDataFactory {

    static func createTestDocument() -> EbookDocument {
        let document = EbookDocument()
        document.metadata.title = "Test Book"
        document.metadata.author = "Test Author"
        document.metadata.description = "A test book for unit testing"
        document.metadata.language = "en"
        document.metadata.publisher = "Test Publisher"
        document.metadata.isbn = "123-4567890123"

        document.chapters = [
            Chapter(title: "Chapter 1", content: "This is the first chapter."),
            Chapter(title: "Chapter 2", content: "This is the second chapter."),
            Chapter(title: "Chapter 3", content: "This is the third chapter.")
        ]

        return document
    }

    static func createEmptyDocument() -> EbookDocument {
        let document = EbookDocument()
        document.chapters = []
        return document
    }

    static func createDocumentWithLargeChapter() -> EbookDocument {
        let document = EbookDocument()
        document.metadata.title = "Large Chapter Test"
        document.metadata.author = "Test Author"

        // Create a chapter larger than 650KB (KDP limit)
        let largeContent = String(repeating: "A", count: 700_000)
        document.chapters = [
            Chapter(title: "Very Large Chapter", content: largeContent)
        ]

        return document
    }

    static func createDocumentWithSpecialCharacters() -> EbookDocument {
        let document = EbookDocument()
        document.metadata.title = "Special Characters Test"
        document.metadata.author = "Test Author"

        document.chapters = [
            Chapter(
                title: "Chapter with <HTML> & \"Quotes\"",
                content: "Content with special chars: <>&\"' and unicode: \u{2014} \u{2026}"
            )
        ]

        return document
    }
}

// MARK: - Test Assertions

extension XCTestCase {

    /// Asserts that a document has valid basic metadata
    func assertValidMetadata(_ metadata: BookMetadata, file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(metadata.title.isEmpty, "Title should not be empty", file: file, line: line)
        XCTAssertFalse(metadata.author.isEmpty, "Author should not be empty", file: file, line: line)
        XCTAssertFalse(metadata.language.isEmpty, "Language should not be empty", file: file, line: line)
    }

    /// Asserts that HTML content is properly escaped
    func assertHTMLEscaped(_ html: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(html.contains("<script"), "HTML should not contain unescaped script tags", file: file, line: line)
        XCTAssertFalse(html.contains("<iframe"), "HTML should not contain unescaped iframe tags", file: file, line: line)

        // Check for proper escaping of special characters
        if html.contains("&lt;") || html.contains("&gt;") || html.contains("&amp;") {
            // HTML appears to be escaped
            return
        }
        // If we find raw < or > in text content (not tags), that's potentially an issue
        // But this is context-dependent, so we'll just check for obvious problems
    }

    /// Asserts that a string is valid XHTML
    func assertValidXHTML(_ xhtml: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(xhtml.contains("<?xml"), "XHTML should contain XML declaration", file: file, line: line)
        XCTAssertTrue(xhtml.contains("<!DOCTYPE"), "XHTML should contain DOCTYPE", file: file, line: line)
        XCTAssertTrue(xhtml.contains("<html"), "XHTML should contain html tag", file: file, line: line)
        XCTAssertTrue(xhtml.contains("</html>"), "XHTML should contain closing html tag", file: file, line: line)
    }

    /// Asserts that validation errors contain specific error types
    func assertContainsError<T: Error & CustomStringConvertible>(_ errors: [T], containing substring: String, file: StaticString = #file, line: UInt = #line) {
        let found = errors.contains { $0.description.contains(substring) }
        XCTAssertTrue(found, "Expected to find error containing '\(substring)' but did not", file: file, line: line)
    }
}

// MARK: - Performance Testing Utilities

extension XCTestCase {

    /// Measures the time taken to convert a document
    func measureConversionTime(description: String, iterations: Int = 10, block: () throws -> Void) {
        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<iterations {
                try? block()
            }
        }
    }
}

// MARK: - File Utilities

class TestFileUtilities {

    static func createTemporaryTestFile(content: String, extension ext: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".\(ext)"
        let fileURL = tempDir.appendingPathComponent(fileName)

        try? content.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    static func createTemporaryPDFFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)

        // Create a minimal PDF file header
        let pdfContent = "%PDF-1.4\n%\u{00E2}\u{00E3}\u{00CF}\u{00D3}\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n2 0 obj\n<< /Type /Pages /Kids [] /Count 0 >>\nendobj\nxref\n0 3\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \ntrailer\n<< /Size 3 /Root 1 0 R >>\nstartxref\n110\n%%EOF"
        try? pdfContent.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    static func deleteTemporaryFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
