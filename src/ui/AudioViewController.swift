import Cocoa

class AudioViewController: NSViewController {
    
    private let audioController = AudioController()
    private let textToSpeech = TextToSpeech()
    
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var statusLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUIForPlaybackState(isPlaying: false)
    }
    
    @IBAction func playButtonClicked(_ sender: NSButton) {
        let textToRead = "Your text goes here." // Replace with actual text input
        textToSpeech.speak(text: textToRead)
        audioController.playAudio()
        updateUIForPlaybackState(isPlaying: true)
    }
    
    @IBAction func stopButtonClicked(_ sender: NSButton) {
        textToSpeech.stopSpeaking()
        audioController.stopAudio()
        updateUIForPlaybackState(isPlaying: false)
    }
    
    private func updateUIForPlaybackState(isPlaying: Bool) {
        playButton.isEnabled = !isPlaying
        stopButton.isEnabled = isPlaying
        statusLabel.stringValue = isPlaying ? "Playing..." : "Stopped"
    }
}