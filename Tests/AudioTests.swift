import XCTest
import AVFoundation
@testable import AvantGarde

class AudioTests: XCTestCase {

    var mockTTS: MockTextToSpeech!
    var audioController: AudioController!
    var mockDelegate: MockAudioControllerDelegate!

    override func setUp() {
        super.setUp()
        mockTTS = MockTextToSpeech()
        audioController = AudioController(textToSpeech: mockTTS)
        mockDelegate = MockAudioControllerDelegate()
        audioController.delegate = mockDelegate
    }

    override func tearDown() {
        mockTTS = nil
        audioController = nil
        mockDelegate = nil
        super.tearDown()
    }

    func testTextToSpeechSpeak() {
        mockTTS.speak(text: "Hello, this is a test.")
        XCTAssertTrue(mockTTS.speakCalled)
        XCTAssertEqual(mockTTS.lastSpokenText, "Hello, this is a test.")
        XCTAssertTrue(mockTTS.isSpeaking)
        
        mockTTS.stopSpeaking()
        XCTAssertTrue(mockTTS.stopCalled)
        XCTAssertFalse(mockTTS.isSpeaking)
    }

    func testTextToSpeechPauseResume() {
        mockTTS.speak(text: "Pause test")
        XCTAssertTrue(mockTTS.isSpeaking)
        
        mockTTS.pauseSpeaking()
        XCTAssertTrue(mockTTS.pauseCalled)
        XCTAssertTrue(mockTTS.isPaused)
        
        mockTTS.continueSpeaking()
        XCTAssertTrue(mockTTS.continueCalled)
        XCTAssertFalse(mockTTS.isPaused)
    }

    func testAudioControllerReadText() {
        audioController.readTextAloud("Hello from AudioController")
        XCTAssertTrue(mockTTS.speakCalled)
        XCTAssertEqual(mockTTS.lastSpokenText, "Hello from AudioController")
        XCTAssertTrue(audioController.isReadingText)
        
        audioController.stopTextToSpeech()
        XCTAssertTrue(mockTTS.stopCalled)
        XCTAssertFalse(audioController.isReadingText)
    }

    func testAudioControllerReadDocument() {
        let document = TestDataFactory.createTestDocument()
        audioController.readDocument(document)
        
        XCTAssertTrue(mockTTS.speakCalled)
        XCTAssertTrue(audioController.isReadingText)
        XCTAssertEqual(audioController.currentChapterIndex, 0)
        
        // Test navigation
        audioController.readNextChapter()
        XCTAssertEqual(audioController.currentChapterIndex, 1)
        
        audioController.readPreviousChapter()
        XCTAssertEqual(audioController.currentChapterIndex, 0)
        
        audioController.stopTextToSpeech()
        XCTAssertFalse(audioController.isReadingText)
    }
}
