import XCTest
@testable import ebook_converter_macos

class ConverterTests: XCTestCase {

    var kdpConverter: KDPConverter!
    var googleConverter: GoogleConverter!

    override func setUp() {
        super.setUp()
        kdpConverter = KDPConverter()
        googleConverter = GoogleConverter()
    }

    override func tearDown() {
        kdpConverter = nil
        googleConverter = nil
        super.tearDown()
    }

    // MARK: - KDP Converter Tests

    func testKDPConvertToKDP_ValidDocument() async throws {
        let document = TestDataFactory.createTestDocument()

        let data = try await kdpConverter.convertToKDP(document: document)

        XCTAssertFalse(data.isEmpty, "Converted data should not be empty")

        let html = String(data: data, encoding: .utf8)
        XCTAssertNotNil(html, "Data should be valid UTF-8")

        if let html = html {
            assertValidXHTML(html)
            XCTAssertTrue(html.contains(document.metadata.title), "HTML should contain document title")
            XCTAssertTrue(html.contains(document.metadata.author), "HTML should contain author")
            XCTAssertTrue(html.contains("Chapter 1"), "HTML should contain chapter titles")
        }
    }

    func testKDPConvertToKDP_HTMLEscaping() async throws {
        let document = TestDataFactory.createDocumentWithSpecialCharacters()

        let data = try await kdpConverter.convertToKDP(document: document)
        let html = String(data: data, encoding: .utf8)

        XCTAssertNotNil(html)
        if let html = html {
            // Check that special characters are escaped
            XCTAssertTrue(html.contains("&lt;") || html.contains("&gt;"), "HTML should escape < and >")
            XCTAssertTrue(html.contains("&amp;"), "HTML should escape &")
            XCTAssertTrue(html.contains("&quot;"), "HTML should escape quotes")
        }
    }

    func testKDPValidation_ValidDocument() {
        let document = TestDataFactory.createTestDocument()

        let errors = kdpConverter.validateForKDP(document)

        XCTAssertTrue(errors.isEmpty, "Valid document should have no errors")
    }

    func testKDPValidation_MissingTitle() {
        let document = EbookDocument()
        document.metadata.title = ""
        document.metadata.author = "Test Author"
        document.chapters = [Chapter(title: "Chapter 1", content: "Content")]

        let errors = kdpConverter.validateForKDP(document)

        XCTAssertFalse(errors.isEmpty, "Document without title should have errors")
        assertContainsError(errors, containing: "title")
    }

    func testKDPValidation_EmptyContent() {
        let document = TestDataFactory.createEmptyDocument()
        document.metadata.title = "Test"
        document.metadata.author = "Test Author"

        let errors = kdpConverter.validateForKDP(document)

        XCTAssertFalse(errors.isEmpty, "Document without chapters should have errors")
        assertContainsError(errors, containing: "no chapters")
    }

    func testKDPValidation_LargeChapter() {
        let document = TestDataFactory.createDocumentWithLargeChapter()
        document.metadata.title = "Test"
        document.metadata.author = "Test Author"

        let errors = kdpConverter.validateForKDP(document)

        XCTAssertFalse(errors.isEmpty, "Document with large chapter should have warnings")
        assertContainsError(errors, containing: "too large")
    }

    // MARK: - Google Converter Tests

    func testGoogleConvertToEPUB_ValidDocument() async throws {
        let document = TestDataFactory.createTestDocument()

        let data = try await googleConverter.convertToGoogle(document: document)

        XCTAssertFalse(data.isEmpty, "Converted data should not be empty")

        let html = String(data: data, encoding: .utf8)
        XCTAssertNotNil(html, "Data should be valid UTF-8")

        if let html = html {
            assertValidXHTML(html)
            XCTAssertTrue(html.contains(document.metadata.title), "EPUB should contain document title")
            XCTAssertTrue(html.contains(document.metadata.author), "EPUB should contain author")
            XCTAssertTrue(html.contains("Table of Contents"), "EPUB should have table of contents")
        }
    }

    func testGoogleConvertToEPUB_DublinCoreMetadata() async throws {
        let document = TestDataFactory.createTestDocument()

        let data = try await googleConverter.convertToGoogle(document: document)
        let html = String(data: data, encoding: .utf8)

        XCTAssertNotNil(html)
        if let html = html {
            // Check for Dublin Core metadata
            XCTAssertTrue(html.contains("dc:title"), "EPUB should contain Dublin Core title")
            XCTAssertTrue(html.contains("dc:creator"), "EPUB should contain Dublin Core creator")
            XCTAssertTrue(html.contains("dc:publisher"), "EPUB should contain Dublin Core publisher")
            XCTAssertTrue(html.contains("dc:language"), "EPUB should contain Dublin Core language")
        }
    }

    func testGoogleValidation_ValidDocument() {
        let document = TestDataFactory.createTestDocument()

        let errors = googleConverter.validateForGooglePlayBooks(document)

        // May have info messages, but should not have critical errors
        let criticalErrors = errors.filter { $0.severity == .error }
        XCTAssertTrue(criticalErrors.isEmpty, "Valid document should have no critical errors")
    }

    func testGoogleValidation_MissingMetadata() {
        let document = EbookDocument()
        document.chapters = [Chapter(title: "Chapter 1", content: "Content")]

        let errors = googleConverter.validateForGooglePlayBooks(document)

        XCTAssertFalse(errors.isEmpty, "Document without metadata should have errors")

        let errorDescriptions = errors.map { $0.description }
        XCTAssertTrue(errorDescriptions.contains(where: { $0.contains("title") }), "Should have title error")
        XCTAssertTrue(errorDescriptions.contains(where: { $0.contains("author") }), "Should have author error")
    }

    func testGoogleValidation_LargeChapter() {
        let document = TestDataFactory.createDocumentWithLargeChapter()
        document.metadata.title = "Test"
        document.metadata.author = "Test Author"
        document.metadata.language = "en"

        let errors = googleConverter.validateForGooglePlayBooks(document)

        XCTAssertFalse(errors.isEmpty, "Document with large chapter should have warnings")
        assertContainsError(errors, containing: "too large")
    }

    // MARK: - Performance Tests

    func testKDPConversionPerformance() async throws {
        let document = TestDataFactory.createTestDocument()

        measure {
            Task {
                _ = try? await kdpConverter.convertToKDP(document: document)
            }
        }
    }

    func testGoogleConversionPerformance() async throws {
        let document = TestDataFactory.createTestDocument()

        measure {
            Task {
                _ = try? await googleConverter.convertToGoogle(document: document)
            }
        }
    }
}
