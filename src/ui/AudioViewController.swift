import Cocoa

class AudioViewController: NSViewController {

    private let audioController: AudioController
    private var currentDocument: EbookDocument?

    // MARK: - Initialization

    /// Initialize with an optional AudioController instance (dependency injection)
    /// - Parameter audioController: The AudioController instance to use (defaults to ServiceContainer)
    init(audioController: AudioController? = nil) {
        self.audioController = audioController ?? ServiceContainer.shared.audioController
        super.init(nibName: nil, bundle: nil)
        Logger.debug("AudioViewController initialized with dependency injection", category: .audio)
    }

    required init?(coder: NSCoder) {
        self.audioController = ServiceContainer.shared.audioController
        super.init(coder: coder)
        Logger.debug("AudioViewController initialized from coder with ServiceContainer", category: .audio)
    }

    // UI Elements - created programmatically
    private var playButton: NSButton!
    private var pauseButton: NSButton!
    private var stopButton: NSButton!
    private var previousChapterButton: NSButton!
    private var nextChapterButton: NSButton!
    private var statusLabel: NSTextField!
    private var chapterLabel: NSTextField!
    private var progressIndicator: NSProgressIndicator!

    override func loadView() {
        // Create the main view
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        setupUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        audioController.delegate = self
        updateUIForPlaybackState()
        Logger.info("AudioViewController loaded", category: .audio)
    }

    private func setupUI() {
        // Chapter label
        chapterLabel = NSTextField(labelWithString: "No document loaded")
        chapterLabel.font = NSFont.boldSystemFont(ofSize: 14)
        chapterLabel.alignment = .center
        chapterLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chapterLabel)

        // Status label
        statusLabel = NSTextField(labelWithString: "Stopped")
        statusLabel.alignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Progress indicator
        progressIndicator = NSProgressIndicator()
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 100
        progressIndicator.doubleValue = 0
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressIndicator)

        // Previous chapter button
        previousChapterButton = NSButton(title: "◀︎ Previous", target: self, action: #selector(previousChapterClicked))
        previousChapterButton.bezelStyle = .rounded
        previousChapterButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previousChapterButton)

        // Play button
        playButton = NSButton(title: "▶︎ Play", target: self, action: #selector(playButtonClicked))
        playButton.bezelStyle = .rounded
        playButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playButton)

        // Pause button
        pauseButton = NSButton(title: "⏸ Pause", target: self, action: #selector(pauseButtonClicked))
        pauseButton.bezelStyle = .rounded
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pauseButton)

        // Stop button
        stopButton = NSButton(title: "⏹ Stop", target: self, action: #selector(stopButtonClicked))
        stopButton.bezelStyle = .rounded
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stopButton)

        // Next chapter button
        nextChapterButton = NSButton(title: "Next ▶︎", target: self, action: #selector(nextChapterClicked))
        nextChapterButton.bezelStyle = .rounded
        nextChapterButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextChapterButton)

        // Set up constraints
        NSLayoutConstraint.activate([
            chapterLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            chapterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            chapterLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            chapterLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: chapterLabel.bottomAnchor, constant: 10),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            progressIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            progressIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            previousChapterButton.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 30),
            previousChapterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            playButton.centerYAnchor.constraint(equalTo: previousChapterButton.centerYAnchor),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -60),

            pauseButton.centerYAnchor.constraint(equalTo: previousChapterButton.centerYAnchor),
            pauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            stopButton.centerYAnchor.constraint(equalTo: previousChapterButton.centerYAnchor),
            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 60),

            nextChapterButton.centerYAnchor.constraint(equalTo: previousChapterButton.centerYAnchor),
            nextChapterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Document Management

    func loadDocument(_ document: EbookDocument) {
        Logger.info("Loading document for audio playback: \(document.metadata.title)", category: .audio)
        currentDocument = document
        updateChapterLabel()
        updateUIForPlaybackState()
    }

    // MARK: - Button Actions

    @objc func playButtonClicked() {
        guard let document = currentDocument else {
            Logger.warning("Play clicked with no document loaded", category: .audio)
            showAlert(title: "No Document", message: "Please load a document before playing audio.")
            return
        }

        if audioController.isPaused {
            Logger.info("Resuming audio playback", category: .audio)
            audioController.resumeTextToSpeech()
        } else {
            Logger.info("Starting audio playback from beginning", category: .audio)
            audioController.readDocument(document, startingFromChapter: 0)
        }

        updateUIForPlaybackState()
    }

    @objc func pauseButtonClicked() {
        Logger.info("Pausing audio playback", category: .audio)
        audioController.pauseTextToSpeech()
        updateUIForPlaybackState()
    }

    @objc func stopButtonClicked() {
        Logger.info("Stopping audio playback", category: .audio)
        audioController.stopTextToSpeech()
        progressIndicator.doubleValue = 0
        updateUIForPlaybackState()
    }

    @objc func previousChapterClicked() {
        Logger.info("Previous chapter requested", category: .audio)
        audioController.readPreviousChapter()
        updateChapterLabel()
    }

    @objc func nextChapterClicked() {
        Logger.info("Next chapter requested", category: .audio)
        audioController.readNextChapter()
        updateChapterLabel()
    }

    // MARK: - UI Updates

    private func updateUIForPlaybackState() {
        let isPlaying = audioController.isPlaying
        let isPaused = audioController.isPaused

        playButton.isEnabled = !isPlaying || isPaused
        pauseButton.isEnabled = isPlaying && !isPaused
        stopButton.isEnabled = isPlaying || isPaused

        let hasDocument = currentDocument != nil
        previousChapterButton.isEnabled = hasDocument && (audioController.currentChapterIndex > 0 || !isPlaying)
        nextChapterButton.isEnabled = hasDocument

        if isPlaying && !isPaused {
            statusLabel.stringValue = "Playing..."
        } else if isPaused {
            statusLabel.stringValue = "Paused"
        } else {
            statusLabel.stringValue = "Stopped"
        }
    }

    private func updateChapterLabel() {
        if let playbackInfo = audioController.getPlaybackInfo() {
            chapterLabel.stringValue = "\(playbackInfo.chapterTitle) (\(playbackInfo.currentChapter) of \(playbackInfo.totalChapters))"
        } else if let document = currentDocument {
            chapterLabel.stringValue = "\(document.metadata.title) - Ready"
        } else {
            chapterLabel.stringValue = "No document loaded"
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - AudioControllerDelegate

extension AudioViewController: AudioControllerDelegate {

    func audioDidStart() {
        Logger.debug("Audio started - updating UI", category: .audio)
        updateUIForPlaybackState()
        updateChapterLabel()
    }

    func audioDidFinish() {
        Logger.debug("Audio finished - updating UI", category: .audio)
        progressIndicator.doubleValue = 0
        updateUIForPlaybackState()
        updateChapterLabel()
    }

    func audioDidPause() {
        Logger.debug("Audio paused - updating UI", category: .audio)
        updateUIForPlaybackState()
    }

    func audioPlaybackProgress(_ progress: Float) {
        progressIndicator.doubleValue = Double(progress * 100)
    }

    func audioError(_ error: Error) {
        Logger.error("Audio playback error", error: error, category: .audio)
        showAlert(title: "Playback Error", message: "An error occurred during playback: \(error.localizedDescription)")
        updateUIForPlaybackState()
    }
}