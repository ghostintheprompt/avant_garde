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

    func testConvertToKDP() {
        let inputEbook = "path/to/input.ebook"
        let expectedOutput = "path/to/output.kdp"
        
        let result = kdpConverter.convertToKDP(inputEbook)
        
        XCTAssertEqual(result, expectedOutput, "KDP conversion did not produce the expected output.")
    }

    func testConvertFromKDP() {
        let inputKDP = "path/to/input.kdp"
        let expectedOutput = "path/to/output.ebook"
        
        let result = kdpConverter.convertFromKDP(inputKDP)
        
        XCTAssertEqual(result, expectedOutput, "KDP to eBook conversion did not produce the expected output.")
    }

    func testConvertToGoogle() {
        let inputEbook = "path/to/input.ebook"
        let expectedOutput = "path/to/output.google"
        
        let result = googleConverter.convertToGoogle(inputEbook)
        
        XCTAssertEqual(result, expectedOutput, "Google format conversion did not produce the expected output.")
    }

    func testConvertFromGoogle() {
        let inputGoogle = "path/to/input.google"
        let expectedOutput = "path/to/output.ebook"
        
        let result = googleConverter.convertFromGoogle(inputGoogle)
        
        XCTAssertEqual(result, expectedOutput, "Google to eBook conversion did not produce the expected output.")
    }
}