import Cocoa

class ConversionViewController: NSViewController {

    // UI Elements - created programmatically
    private var sourceFormatPopup: NSPopUpButton!
    private var targetFormatPopup: NSPopUpButton!
    private var convertButton: NSButton!
    private var statusLabel: NSTextField!

    override func loadView() {
        // Create the main view
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 300))
        setupUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFormats()
    }

    private func setupUI() {
        // Title label
        let titleLabel = NSTextField(labelWithString: "Ebook Format Converter")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Source format label
        let sourceLabel = NSTextField(labelWithString: "Source Format:")
        sourceLabel.isEditable = false
        sourceLabel.isBordered = false
        sourceLabel.backgroundColor = .clear
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sourceLabel)

        // Source format popup
        sourceFormatPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        sourceFormatPopup.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sourceFormatPopup)

        // Target format label
        let targetLabel = NSTextField(labelWithString: "Target Format:")
        targetLabel.isEditable = false
        targetLabel.isBordered = false
        targetLabel.backgroundColor = .clear
        targetLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(targetLabel)

        // Target format popup
        targetFormatPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        targetFormatPopup.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(targetFormatPopup)

        // Convert button
        convertButton = NSButton(title: "Convert", target: self, action: #selector(convertButtonClicked(_:)))
        convertButton.bezelStyle = .rounded
        convertButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(convertButton)

        // Status label
        statusLabel = NSTextField(labelWithString: "Ready to convert")
        statusLabel.isEditable = false
        statusLabel.isBordered = false
        statusLabel.backgroundColor = .clear
        statusLabel.alignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Set up constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40),

            sourceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            sourceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            sourceLabel.widthAnchor.constraint(equalToConstant: 120),

            sourceFormatPopup.centerYAnchor.constraint(equalTo: sourceLabel.centerYAnchor),
            sourceFormatPopup.leadingAnchor.constraint(equalTo: sourceLabel.trailingAnchor, constant: 10),
            sourceFormatPopup.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            targetLabel.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 20),
            targetLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            targetLabel.widthAnchor.constraint(equalToConstant: 120),

            targetFormatPopup.centerYAnchor.constraint(equalTo: targetLabel.centerYAnchor),
            targetFormatPopup.leadingAnchor.constraint(equalTo: targetLabel.trailingAnchor, constant: 10),
            targetFormatPopup.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            convertButton.topAnchor.constraint(equalTo: targetLabel.bottomAnchor, constant: 30),
            convertButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            convertButton.widthAnchor.constraint(equalToConstant: 120),

            statusLabel.topAnchor.constraint(equalTo: convertButton.bottomAnchor, constant: 20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -80)
        ])
    }
    
    private func setupFormats() {
        // Populate the format options
        sourceFormatPopup.addItems(withTitles: EbookFormat.allCases.map { $0.rawValue })
        targetFormatPopup.addItems(withTitles: EbookFormat.allCases.map { $0.rawValue })
    }
    
    @objc func convertButtonClicked(_ sender: NSButton) {
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
        converter.convert(from: source) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
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
        // Use ServiceContainer for dependency
        let textToSpeech = ServiceContainer.shared.textToSpeech
        textToSpeech.speak(text)
    }
}