import AppKit
import AVFoundation

class VoiceSettingsViewController: NSViewController {

    // UI Elements - created programmatically
    private var voiceTableView: NSTableView!
    private var voicePreviewButton: NSButton!
    private var speechRateSlider: NSSlider!
    private var speechPitchSlider: NSSlider!
    private var speechVolumeSlider: NSSlider!
    private var rateLabel: NSTextField!
    private var pitchLabel: NSTextField!
    private var volumeLabel: NSTextField!
    private var voiceQualitySegmentedControl: NSSegmentedControl!
    private var languagePopUpButton: NSPopUpButton!

    private let textToSpeech: TextToSpeech
    private var displayedVoices: [VoiceOption] = []
    private var selectedVoice: VoiceOption?

    private let previewText = "Hello, this is a preview of how this voice will sound when reading your ebook. The voice quality and speech rate can be adjusted to your preference."

    // MARK: - Initialization

    /// Initialize with an optional TextToSpeech instance (dependency injection)
    /// - Parameter textToSpeech: The TextToSpeech instance to use (defaults to ServiceContainer)
    init(textToSpeech: TextToSpeech? = nil) {
        self.textToSpeech = textToSpeech ?? ServiceContainer.shared.textToSpeech
        super.init(nibName: nil, bundle: nil)
        Logger.debug("VoiceSettingsViewController initialized with dependency injection", category: .audio)
    }

    required init?(coder: NSCoder) {
        self.textToSpeech = ServiceContainer.shared.textToSpeech
        super.init(coder: coder)
        Logger.debug("VoiceSettingsViewController initialized from coder with ServiceContainer", category: .audio)
    }

    override func loadView() {
        // Create the main view
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        createUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadVoices()
        setupTableView()
        textToSpeech.delegate = self
    }

    private func createUI() {
        // Title
        let titleLabel = NSTextField(labelWithString: "Voice Settings")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Voice quality segmented control
        voiceQualitySegmentedControl = NSSegmentedControl(frame: .zero)
        voiceQualitySegmentedControl.segmentCount = 3
        voiceQualitySegmentedControl.setLabel("All", forSegment: 0)
        voiceQualitySegmentedControl.setLabel("Standard", forSegment: 1)
        voiceQualitySegmentedControl.setLabel("Premium", forSegment: 2)
        voiceQualitySegmentedControl.selectedSegment = 0
        voiceQualitySegmentedControl.target = self
        voiceQualitySegmentedControl.action = #selector(voiceQualityChanged(_:))
        voiceQualitySegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(voiceQualitySegmentedControl)

        // Language popup
        languagePopUpButton = NSPopUpButton(frame: .zero, pullsDown: false)
        languagePopUpButton.target = self
        languagePopUpButton.action = #selector(languageChanged(_:))
        languagePopUpButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(languagePopUpButton)

        // Table view for voices
        let scrollView = NSScrollView(frame: .zero)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        voiceTableView = NSTableView(frame: scrollView.bounds)
        scrollView.documentView = voiceTableView

        // Preview button
        voicePreviewButton = NSButton(title: "Preview Voice", target: self, action: #selector(previewVoice(_:)))
        voicePreviewButton.bezelStyle = .rounded
        voicePreviewButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(voicePreviewButton)

        // Speech rate controls
        let rateTitle = NSTextField(labelWithString: "Speech Rate:")
        rateTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rateTitle)

        speechRateSlider = NSSlider(target: self, action: #selector(speechRateChanged(_:)))
        speechRateSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speechRateSlider)

        rateLabel = NSTextField(labelWithString: "0.50")
        rateLabel.isEditable = false
        rateLabel.isBordered = false
        rateLabel.backgroundColor = .clear
        rateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rateLabel)

        // Speech pitch controls
        let pitchTitle = NSTextField(labelWithString: "Pitch:")
        pitchTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pitchTitle)

        speechPitchSlider = NSSlider(target: self, action: #selector(speechPitchChanged(_:)))
        speechPitchSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speechPitchSlider)

        pitchLabel = NSTextField(labelWithString: "1.00")
        pitchLabel.isEditable = false
        pitchLabel.isBordered = false
        pitchLabel.backgroundColor = .clear
        pitchLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pitchLabel)

        // Speech volume controls
        let volumeTitle = NSTextField(labelWithString: "Volume:")
        volumeTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(volumeTitle)

        speechVolumeSlider = NSSlider(target: self, action: #selector(speechVolumeChanged(_:)))
        speechVolumeSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speechVolumeSlider)

        volumeLabel = NSTextField(labelWithString: "100%")
        volumeLabel.isEditable = false
        volumeLabel.isBordered = false
        volumeLabel.backgroundColor = .clear
        volumeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(volumeLabel)

        // Reset button
        let resetButton = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetToDefaults(_:)))
        resetButton.bezelStyle = .rounded
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resetButton)

        // Set up constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            voiceQualitySegmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            voiceQualitySegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            voiceQualitySegmentedControl.widthAnchor.constraint(equalToConstant: 200),

            languagePopUpButton.centerYAnchor.constraint(equalTo: voiceQualitySegmentedControl.centerYAnchor),
            languagePopUpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            languagePopUpButton.widthAnchor.constraint(equalToConstant: 200),

            scrollView.topAnchor.constraint(equalTo: voiceQualitySegmentedControl.bottomAnchor, constant: 15),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.heightAnchor.constraint(equalToConstant: 150),

            voicePreviewButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 10),
            voicePreviewButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            rateTitle.topAnchor.constraint(equalTo: voicePreviewButton.bottomAnchor, constant: 20),
            rateTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            rateTitle.widthAnchor.constraint(equalToConstant: 100),

            speechRateSlider.centerYAnchor.constraint(equalTo: rateTitle.centerYAnchor),
            speechRateSlider.leadingAnchor.constraint(equalTo: rateTitle.trailingAnchor, constant: 10),
            speechRateSlider.trailingAnchor.constraint(equalTo: rateLabel.leadingAnchor, constant: -10),

            rateLabel.centerYAnchor.constraint(equalTo: rateTitle.centerYAnchor),
            rateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            rateLabel.widthAnchor.constraint(equalToConstant: 50),

            pitchTitle.topAnchor.constraint(equalTo: rateTitle.bottomAnchor, constant: 15),
            pitchTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pitchTitle.widthAnchor.constraint(equalToConstant: 100),

            speechPitchSlider.centerYAnchor.constraint(equalTo: pitchTitle.centerYAnchor),
            speechPitchSlider.leadingAnchor.constraint(equalTo: pitchTitle.trailingAnchor, constant: 10),
            speechPitchSlider.trailingAnchor.constraint(equalTo: pitchLabel.leadingAnchor, constant: -10),

            pitchLabel.centerYAnchor.constraint(equalTo: pitchTitle.centerYAnchor),
            pitchLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            pitchLabel.widthAnchor.constraint(equalToConstant: 50),

            volumeTitle.topAnchor.constraint(equalTo: pitchTitle.bottomAnchor, constant: 15),
            volumeTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            volumeTitle.widthAnchor.constraint(equalToConstant: 100),

            speechVolumeSlider.centerYAnchor.constraint(equalTo: volumeTitle.centerYAnchor),
            speechVolumeSlider.leadingAnchor.constraint(equalTo: volumeTitle.trailingAnchor, constant: 10),
            speechVolumeSlider.trailingAnchor.constraint(equalTo: volumeLabel.leadingAnchor, constant: -10),

            volumeLabel.centerYAnchor.constraint(equalTo: volumeTitle.centerYAnchor),
            volumeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            volumeLabel.widthAnchor.constraint(equalToConstant: 50),

            resetButton.topAnchor.constraint(equalTo: volumeTitle.bottomAnchor, constant: 20),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupUI() {
        // Setup sliders
        speechRateSlider.minValue = Double(AVSpeechUtteranceMinimumSpeechRate)
        speechRateSlider.maxValue = Double(AVSpeechUtteranceMaximumSpeechRate)
        speechRateSlider.doubleValue = 0.5
        
        speechPitchSlider.minValue = 0.5
        speechPitchSlider.maxValue = 2.0
        speechPitchSlider.doubleValue = 1.0
        
        speechVolumeSlider.minValue = 0.0
        speechVolumeSlider.maxValue = 1.0
        speechVolumeSlider.doubleValue = 1.0
        
        updateSliderLabels()
        
        // Setup segmented control for voice quality
        voiceQualitySegmentedControl.segmentCount = 3
        voiceQualitySegmentedControl.setLabel("All", forSegment: 0)
        voiceQualitySegmentedControl.setLabel("Standard", forSegment: 1)
        voiceQualitySegmentedControl.setLabel("Premium", forSegment: 2)
        voiceQualitySegmentedControl.selectedSegment = 0
        
        setupLanguagePopUp()
    }
    
    private func setupLanguagePopUp() {
        languagePopUpButton.removeAllItems()
        
        let voicesByLanguage = textToSpeech.getVoicesByLanguage()
        let sortedLanguages = voicesByLanguage.keys.sorted()
        
        languagePopUpButton.addItem(withTitle: "All Languages")
        
        for language in sortedLanguages {
            let languageName = Locale.current.localizedString(forLanguageCode: language) ?? language
            languagePopUpButton.addItem(withTitle: languageName)
            languagePopUpButton.lastItem?.representedObject = language
        }
        
        languagePopUpButton.selectItem(at: 0)
    }
    
    private func setupTableView() {
        voiceTableView.delegate = self
        voiceTableView.dataSource = self
        
        // Create columns
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameColumn.title = "Voice Name"
        nameColumn.width = 200
        voiceTableView.addTableColumn(nameColumn)
        
        let languageColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("language"))
        languageColumn.title = "Language"
        languageColumn.width = 100
        voiceTableView.addTableColumn(languageColumn)
        
        let qualityColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("quality"))
        qualityColumn.title = "Quality"
        qualityColumn.width = 80
        voiceTableView.addTableColumn(qualityColumn)
    }
    
    private func loadVoices() {
        filterVoices()
    }
    
    private func filterVoices() {
        var voices = textToSpeech.availableVoices
        
        // Filter by quality
        switch voiceQualitySegmentedControl.selectedSegment {
        case 1: // Standard
            voices = voices.filter { $0.quality == .default }
        case 2: // Premium
            voices = voices.filter { $0.quality == .enhanced }
        default: // All
            break
        }
        
        // Filter by language
        if languagePopUpButton.indexOfSelectedItem > 0,
           let selectedLanguage = languagePopUpButton.selectedItem?.representedObject as? String {
            voices = voices.filter { $0.language.hasPrefix(selectedLanguage) }
        }
        
        displayedVoices = voices.sorted { $0.displayName < $1.displayName }
        voiceTableView.reloadData()
        
        // Select current voice if it's in the filtered list
        if let currentVoice = textToSpeech.getCurrentVoice(),
           let index = displayedVoices.firstIndex(where: { $0.voice.identifier == currentVoice.voice.identifier }) {
            voiceTableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            selectedVoice = currentVoice
        }
    }
    
    private func updateSliderLabels() {
        rateLabel.stringValue = String(format: "%.2f", speechRateSlider.doubleValue)
        pitchLabel.stringValue = String(format: "%.2f", speechPitchSlider.doubleValue)
        volumeLabel.stringValue = String(format: "%.0f%%", speechVolumeSlider.doubleValue * 100)
    }
    
    // MARK: - Actions
    
    @objc func voiceQualityChanged(_ sender: NSSegmentedControl) {
        filterVoices()
    }

    @objc func languageChanged(_ sender: NSPopUpButton) {
        filterVoices()
    }

    @objc func speechRateChanged(_ sender: NSSlider) {
        textToSpeech.setSpeechRate(Float(sender.doubleValue))
        updateSliderLabels()
    }

    @objc func speechPitchChanged(_ sender: NSSlider) {
        textToSpeech.setSpeechPitch(Float(sender.doubleValue))
        updateSliderLabels()
    }

    @objc func speechVolumeChanged(_ sender: NSSlider) {
        textToSpeech.setSpeechVolume(Float(sender.doubleValue))
        updateSliderLabels()
    }

    @objc func previewVoice(_ sender: NSButton) {
        guard let voice = selectedVoice else {
            showAlert(message: "Please select a voice to preview")
            return
        }
        
        if textToSpeech.isSpeaking {
            textToSpeech.stopSpeaking()
            voicePreviewButton.title = "Preview Voice"
        } else {
            textToSpeech.setVoice(voice)
            textToSpeech.speak(text: previewText)
            voicePreviewButton.title = "Stop Preview"
        }
    }
    
    @objc func resetToDefaults(_ sender: NSButton) {
        speechRateSlider.doubleValue = 0.5
        speechPitchSlider.doubleValue = 1.0
        speechVolumeSlider.doubleValue = 1.0
        
        textToSpeech.setSpeechRate(0.5)
        textToSpeech.setSpeechPitch(1.0)
        textToSpeech.setSpeechVolume(1.0)
        
        updateSliderLabels()
        
        // Select recommended voice
        let recommended = textToSpeech.getRecommendedVoices()
        if let firstRecommended = recommended.first,
           let index = displayedVoices.firstIndex(where: { $0.voice.identifier == firstRecommended.voice.identifier }) {
            voiceTableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            selectedVoice = firstRecommended
            textToSpeech.setVoice(firstRecommended)
        }
    }
    
    @objc func showRecommendedVoices(_ sender: NSButton) {
        let recommended = textToSpeech.getRecommendedVoices()
        
        let alert = NSAlert()
        alert.messageText = "Recommended Voices for Audiobooks"
        alert.informativeText = "These voices are optimized for long-form reading:\n\n" +
            recommended.map { "• \($0.displayName) (\($0.language))" }.joined(separator: "\n")
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - NSTableViewDataSource

extension VoiceSettingsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return displayedVoices.count
    }
}

// MARK: - NSTableViewDelegate

extension VoiceSettingsViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < displayedVoices.count else { return nil }
        
        let voice = displayedVoices[row]
        let cellIdentifier = tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("")
        
        var cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView
        
        if cellView == nil {
            cellView = NSTableCellView()
            cellView?.identifier = cellIdentifier
            
            let textField = NSTextField()
            textField.isBordered = false
            textField.isEditable = false
            textField.backgroundColor = .clear
            textField.translatesAutoresizingMaskIntoConstraints = false
            
            cellView?.addSubview(textField)
            cellView?.textField = textField
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor)
            ])
        }
        
        switch tableColumn?.identifier.rawValue {
        case "name":
            cellView?.textField?.stringValue = voice.displayName
        case "language":
            let languageName = Locale.current.localizedString(forLanguageCode: voice.language) ?? voice.language
            cellView?.textField?.stringValue = languageName
        case "quality":
            cellView?.textField?.stringValue = voice.quality == .enhanced ? "Premium" : "Standard"
        default:
            break
        }
        
        return cellView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = voiceTableView.selectedRow
        
        if selectedRow >= 0 && selectedRow < displayedVoices.count {
            selectedVoice = displayedVoices[selectedRow]
            textToSpeech.setVoice(selectedVoice!)
        }
    }
}

// MARK: - TextToSpeechDelegate

extension VoiceSettingsViewController: TextToSpeechDelegate {
    func speechDidStart() {
        DispatchQueue.main.async { [weak self] in
            self?.voicePreviewButton.title = "Stop Preview"
        }
    }

    func speechDidFinish() {
        DispatchQueue.main.async { [weak self] in
            self?.voicePreviewButton.title = "Preview Voice"
        }
    }
    
    func speechDidPause() {
        // Handle pause if needed
    }
    
    func speechDidContinue() {
        // Handle continue if needed
    }
    
    func speechProgress(range: NSRange, utterance: AVSpeechUtterance) {
        // Handle progress updates if needed
    }
}
