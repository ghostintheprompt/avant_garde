import Cocoa

class AudioViewController: NSViewController {

    private let audioController = AudioController()
    private let textToSpeech = TextToSpeech()

    // UI Elements - created programmatically
    private var playButton: NSButton!
    private var stopButton: NSButton!
    private var statusLabel: NSTextField!

    override func loadView() {
        // Create the main view
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        setupUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUIForPlaybackState(isPlaying: false)
    }

    private func setupUI() {
        // Create play button
        playButton = NSButton(frame: NSRect(x: 100, y: 150, width: 80, height: 32))
        playButton.title = "Play"
        playButton.bezelStyle = .rounded
        playButton.target = self
        playButton.action = #selector(playButtonClicked(_:))
        playButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playButton)

        // Create stop button
        stopButton = NSButton(frame: NSRect(x: 220, y: 150, width: 80, height: 32))
        stopButton.title = "Stop"
        stopButton.bezelStyle = .rounded
        stopButton.target = self
        stopButton.action = #selector(stopButtonClicked(_:))
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stopButton)

        // Create status label
        statusLabel = NSTextField(frame: NSRect(x: 100, y: 100, width: 200, height: 20))
        statusLabel.stringValue = "Stopped"
        statusLabel.isEditable = false
        statusLabel.isBordered = false
        statusLabel.backgroundColor = .clear
        statusLabel.alignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Set up constraints
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -60),
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 80),

            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 60),
            stopButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stopButton.widthAnchor.constraint(equalToConstant: 80),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 20),
            statusLabel.widthAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    @objc func playButtonClicked(_ sender: NSButton) {
        let textToRead = "Your text goes here." // Replace with actual text input
        textToSpeech.speak(text: textToRead)
        audioController.playAudio()
        updateUIForPlaybackState(isPlaying: true)
    }

    @objc func stopButtonClicked(_ sender: NSButton) {
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