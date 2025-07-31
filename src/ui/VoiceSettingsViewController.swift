import AppKit
import AVFoundation

class VoiceSettingsViewController: NSViewController {
    
    @IBOutlet weak var voiceTableView: NSTableView!
    @IBOutlet weak var voicePreviewButton: NSButton!
    @IBOutlet weak var speechRateSlider: NSSlider!
    @IBOutlet weak var speechPitchSlider: NSSlider!
    @IBOutlet weak var speechVolumeSlider: NSSlider!
    @IBOutlet weak var rateLabel: NSTextField!
    @IBOutlet weak var pitchLabel: NSTextField!
    @IBOutlet weak var volumeLabel: NSTextField!
    @IBOutlet weak var voiceQualitySegmentedControl: NSSegmentedControl!
    @IBOutlet weak var languagePopUpButton: NSPopUpButton!
    
    private let textToSpeech = TextToSpeech()
    private var displayedVoices: [VoiceOption] = []
    private var selectedVoice: VoiceOption?
    
    private let previewText = "Hello, this is a preview of how this voice will sound when reading your ebook. The voice quality and speech rate can be adjusted to your preference."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadVoices()
        setupTableView()
        textToSpeech.delegate = self
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
    
    @IBAction func voiceQualityChanged(_ sender: NSSegmentedControl) {
        filterVoices()
    }
    
    @IBAction func languageChanged(_ sender: NSPopUpButton) {
        filterVoices()
    }
    
    @IBAction func speechRateChanged(_ sender: NSSlider) {
        textToSpeech.setSpeechRate(Float(sender.doubleValue))
        updateSliderLabels()
    }
    
    @IBAction func speechPitchChanged(_ sender: NSSlider) {
        textToSpeech.setSpeechPitch(Float(sender.doubleValue))
        updateSliderLabels()
    }
    
    @IBAction func speechVolumeChanged(_ sender: NSSlider) {
        textToSpeech.setSpeechVolume(Float(sender.doubleValue))
        updateSliderLabels()
    }
    
    @IBAction func previewVoice(_ sender: NSButton) {
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
    
    @IBAction func resetToDefaults(_ sender: NSButton) {
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
    
    @IBAction func showRecommendedVoices(_ sender: NSButton) {
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
        DispatchQueue.main.async {
            self.voicePreviewButton.title = "Stop Preview"
        }
    }
    
    func speechDidFinish() {
        DispatchQueue.main.async {
            self.voicePreviewButton.title = "Preview Voice"
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
