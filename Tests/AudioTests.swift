import XCTest
@testable import ebook_converter_macos

class AudioTests: XCTestCase {

    var textToSpeech: TextToSpeech!
    var audioController: AudioController!

    override func setUp() {
        super.setUp()
        textToSpeech = TextToSpeech()
        audioController = AudioController()
    }

    override func tearDown() {
        textToSpeech = nil
        audioController = nil
        super.tearDown()
    }

    func testTextToSpeechSpeak() {
        let expectation = self.expectation(description: "Text to speech should speak the text")
        
        textToSpeech.speak("Hello, this is a test.") {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testTextToSpeechStopSpeaking() {
        textToSpeech.speak("This will be stopped.")
        textToSpeech.stopSpeaking()
        
        // Assuming there's a way to check if it's stopped, this is a placeholder
        XCTAssertFalse(textToSpeech.isSpeaking)
    }

    func testAudioControllerPlayAudio() {
        let expectation = self.expectation(description: "Audio should play")
        
        audioController.playAudio("testAudio.mp3") {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testAudioControllerStopAudio() {
        audioController.playAudio("testAudio.mp3")
        audioController.stopAudio()
        
        // Assuming there's a way to check if audio is stopped, this is a placeholder
        XCTAssertFalse(audioController.isPlaying)
    }
}