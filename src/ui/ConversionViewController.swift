import Cocoa

class ConversionViewController: NSViewController {
    
    @IBOutlet weak var sourceFormatPopup: NSPopUpButton!
    @IBOutlet weak var targetFormatPopup: NSPopUpButton!
    @IBOutlet weak var convertButton: NSButton!
    @IBOutlet weak var statusLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFormats()
    }
    
    private func setupFormats() {
        // Populate the format options
        sourceFormatPopup.addItems(withTitles: EbookFormat.allCases.map { $0.rawValue })
        targetFormatPopup.addItems(withTitles: EbookFormat.allCases.map { $0.rawValue })
    }
    
    @IBAction func convertButtonClicked(_ sender: NSButton) {
        let sourceFormat = EbookFormat(rawValue: sourceFormatPopup.titleOfSelectedItem ?? "") ?? .unknown
        let targetFormat = EbookFormat(rawValue: targetFormatPopup.titleOfSelectedItem ?? "") ?? .unknown
        
        startConversion(from: sourceFormat, to: targetFormat)
    }
    
    private func startConversion(from source: EbookFormat, to target: EbookFormat) {
        statusLabel.stringValue = "Converting from \(source.rawValue) to \(target.rawValue)..."
        
        // Perform the conversion logic here
        let converter: Converter
        
        switch target {
        case .kdp:
            converter = KDPConverter()
        case .google:
            converter = GoogleConverter()
        default:
            statusLabel.stringValue = "Unsupported conversion format."
            return
        }
        
        // Assuming the converter has a method to handle the conversion
        converter.convert(from: source) { success in
            DispatchQueue.main.async {
                if success {
                    self.statusLabel.stringValue = "Conversion successful!"
                    self.readBackText("Your eBook has been converted successfully.")
                } else {
                    self.statusLabel.stringValue = "Conversion failed."
                }
            }
        }
    }
    
    private func readBackText(_ text: String) {
        let textToSpeech = TextToSpeech()
        textToSpeech.speak(text)
    }
}