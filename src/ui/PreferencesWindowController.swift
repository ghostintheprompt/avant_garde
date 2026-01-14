import AppKit
import Foundation

/// Comprehensive preferences window with theme selection and advanced settings
class PreferencesWindowController: NSWindowController {
    
    private var themeSelectorViewController: ThemeSelectorViewController!
    private var voiceSettingsViewController: VoiceSettingsViewController!
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        self.init(window: window)
        setupWindow()
        setupToolbar()
        setupInitialView()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupWindow() {
        guard let window = window else { return }
        
        window.title = "Ebook Converter Preferences"
        window.center()
        window.minSize = NSSize(width: 800, height: 600)
        window.isReleasedWhenClosed = false
        
        // Make window look modern
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
    }
    
    private func setupToolbar() {
        guard let window = window else { return }
        
        let toolbar = NSToolbar(identifier: "PreferencesToolbar")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.displayMode = .iconAndLabel
        
        window.toolbar = toolbar
        window.toolbarStyle = .preference
    }
    
    private func setupInitialView() {
        showThemePreferences()
    }
    
    @objc private func showThemePreferences() {
        themeSelectorViewController = ThemeSelectorViewController()
        showViewController(themeSelectorViewController, title: "Color Psychology Themes")
    }
    
    @objc private func showVoicePreferences() {
        voiceSettingsViewController = VoiceSettingsViewController()
        showViewController(voiceSettingsViewController, title: "Text-to-Speech Settings")
    }
    
    @objc private func showGeneralPreferences() {
        let generalViewController = GeneralPreferencesViewController()
        showViewController(generalViewController, title: "General Settings")
    }
    
    @objc private func showEditorPreferences() {
        let editorViewController = EditorPreferencesViewController()
        showViewController(editorViewController, title: "Editor Settings")
    }
    
    private func showViewController(_ viewController: NSViewController, title: String) {
        guard let window = window else { return }
        
        // Remove current content
        window.contentView?.subviews.removeAll()
        
        // Add new content
        window.contentViewController = viewController
        window.title = "Preferences - \(title)"
        
        // Animate window resize if needed
        let newSize = viewController.preferredContentSize
        if newSize != .zero {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                window.animator().setContentSize(newSize)
            }
        }
    }
}

// MARK: - Toolbar Delegate

extension PreferencesWindowController: NSToolbarDelegate {
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier {
        case .themes:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Themes"
            item.image = NSImage(systemSymbolName: "paintpalette", accessibilityDescription: "Color Themes")
            item.target = self
            item.action = #selector(showThemePreferences)
            return item
            
        case .voice:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Voice"
            item.image = NSImage(systemSymbolName: "speaker.wave.3", accessibilityDescription: "Voice Settings")
            item.target = self
            item.action = #selector(showVoicePreferences)
            return item
            
        case .general:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "General"
            item.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General Settings")
            item.target = self
            item.action = #selector(showGeneralPreferences)
            return item
            
        case .editor:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Editor"
            item.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "Editor Settings")
            item.target = self
            item.action = #selector(showEditorPreferences)
            return item
            
        default:
            return nil
        }
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.themes, .voice, .editor, .general]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.themes, .voice, .editor, .general, .flexibleSpace]
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.themes, .voice, .editor, .general]
    }
}

// MARK: - Toolbar Item Identifiers

extension NSToolbarItem.Identifier {
    static let themes = NSToolbarItem.Identifier("themes")
    static let voice = NSToolbarItem.Identifier("voice")
    static let general = NSToolbarItem.Identifier("general")
    static let editor = NSToolbarItem.Identifier("editor")
}

// MARK: - General Preferences View Controller

class GeneralPreferencesViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override var preferredContentSize: NSSize {
        return NSSize(width: 600, height: 400)
    }
    
    private func setupView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Auto-save settings
        let autoSaveSection = PreferencesHelpers.createSection(title: "Auto-Save", controls: [
            PreferencesHelpers.createCheckbox(title: "Auto-save documents every 5 minutes", key: "autoSaveEnabled", target: self, action: #selector(checkboxChanged(_:))),
            PreferencesHelpers.createCheckbox(title: "Create backup copies", key: "createBackups", target: self, action: #selector(checkboxChanged(_:))),
            PreferencesHelpers.createTextField(label: "Backup location:", key: "backupPath", placeholder: "~/Documents/Ebook Backups", target: self, action: #selector(textFieldChanged(_:)))
        ])

        // Export settings
        let exportSection = PreferencesHelpers.createSection(title: "Export Settings", controls: [
            PreferencesHelpers.createPopup(label: "Default export format:", items: ["KDP HTML", "Google EPUB", "Both"], key: "defaultExportFormat", target: self, action: #selector(popupChanged(_:))),
            PreferencesHelpers.createCheckbox(title: "Include chapter navigation", key: "includeNavigation", target: self, action: #selector(checkboxChanged(_:))),
            PreferencesHelpers.createCheckbox(title: "Optimize images for e-readers", key: "optimizeImages", target: self, action: #selector(checkboxChanged(_:)))
        ])

        // Startup settings
        let startupSection = PreferencesHelpers.createSection(title: "Startup", controls: [
            PreferencesHelpers.createCheckbox(title: "Restore last session on startup", key: "restoreSession", target: self, action: #selector(checkboxChanged(_:))),
            PreferencesHelpers.createCheckbox(title: "Show welcome screen", key: "showWelcome", target: self, action: #selector(checkboxChanged(_:))),
            PreferencesHelpers.createCheckbox(title: "Check for updates automatically", key: "autoCheckUpdates", target: self, action: #selector(checkboxChanged(_:)))
        ])
        
        stackView.addArrangedSubview(autoSaveSection)
        stackView.addArrangedSubview(exportSection)
        stackView.addArrangedSubview(startupSection)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    // MARK: - Action Handlers

    @objc private func checkboxChanged(_ sender: NSButton) {
        guard let key = sender.identifier?.rawValue else { return }
        UserDefaults.standard.set(sender.state == .on, forKey: key)
    }
    
    @objc private func textFieldChanged(_ sender: NSTextField) {
        guard let key = sender.identifier?.rawValue else { return }
        UserDefaults.standard.set(sender.stringValue, forKey: key)
    }
    
    @objc private func popupChanged(_ sender: NSPopUpButton) {
        guard let key = sender.identifier?.rawValue,
              let selectedTitle = sender.selectedItem?.title else { return }
        UserDefaults.standard.set(selectedTitle, forKey: key)
    }
}

// MARK: - Editor Preferences View Controller

class EditorPreferencesViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override var preferredContentSize: NSSize {
        return NSSize(width: 600, height: 500)
    }
    
    private func setupView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Font settings
        let fontSection = createFontSection()
        
        // Writing settings
        let writingSection = PreferencesHelpers.createSection(title: "Writing Settings", controls: [
            PreferencesHelpers.createCheckbox(title: "Show word count in status bar", key: "showWordCount", target: self, action: #selector(checkboxChanged(_:))),
            PreferencesHelpers.createCheckbox(title: "Highlight misspelled words", key: "spellcheck", target: self, action: #selector(checkboxChanged(_:))),
            PreferencesHelpers.createCheckbox(title: "Auto-correct common mistakes", key: "autocorrect", target: self, action: #selector(checkboxChanged(_:))),
            PreferencesHelpers.createCheckbox(title: "Smart quotes and dashes", key: "smartQuotes", target: self, action: #selector(checkboxChanged(_:)))
        ])

        // Chapter settings
        let chapterSection = PreferencesHelpers.createSection(title: "Chapter Management", controls: [
            PreferencesHelpers.createCheckbox(title: "Auto-number chapters", key: "autoNumberChapters", target: self, action: #selector(checkboxChanged(_:))),
            PreferencesHelpers.createTextField(label: "Chapter prefix:", key: "chapterPrefix", placeholder: "Chapter", target: self, action: #selector(textFieldChanged(_:))),
            PreferencesHelpers.createCheckbox(title: "Show chapter word counts", key: "showChapterCounts", target: self, action: #selector(checkboxChanged(_:)))
        ])

        // Display settings
        let displaySection = PreferencesHelpers.createSection(title: "Display", controls: [
            PreferencesHelpers.createSlider(label: "Text size:", key: "textSize", min: 12, max: 24, target: self, action: #selector(sliderChanged(_:))),
            PreferencesHelpers.createSlider(label: "Line spacing:", key: "lineSpacing", min: 1.0, max: 2.0, target: self, action: #selector(sliderChanged(_:))),
            PreferencesHelpers.createCheckbox(title: "Show ruler", key: "showRuler", target: self, action: #selector(checkboxChanged(_:))),
            PreferencesHelpers.createCheckbox(title: "Wrap text to page width", key: "wrapText", target: self, action: #selector(checkboxChanged(_:)))
        ])
        
        stackView.addArrangedSubview(fontSection)
        stackView.addArrangedSubview(writingSection)
        stackView.addArrangedSubview(chapterSection)
        stackView.addArrangedSubview(displaySection)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func createFontSection() -> NSView {
        let section = NSView()
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Section title
        let titleLabel = NSTextField(labelWithString: "Font Settings")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        stackView.addArrangedSubview(titleLabel)
        
        // Font selector
        let fontContainer = NSView()
        let fontStackView = NSStackView()
        fontStackView.orientation = .horizontal
        fontStackView.spacing = 10
        fontStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let fontLabel = NSTextField(labelWithString: "Editor font:")
        fontLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let fontButton = NSButton()
        fontButton.title = "Select Font..."
        fontButton.bezelStyle = .rounded
        fontButton.target = self
        fontButton.action = #selector(selectFont)
        
        let currentFontLabel = NSTextField(labelWithString: getCurrentFontDescription())
        currentFontLabel.font = NSFont.systemFont(ofSize: 11)
        currentFontLabel.textColor = .secondaryLabelColor
        
        fontStackView.addArrangedSubview(fontLabel)
        fontStackView.addArrangedSubview(fontButton)
        fontStackView.addArrangedSubview(currentFontLabel)
        
        fontContainer.addSubview(fontStackView)
        
        NSLayoutConstraint.activate([
            fontStackView.topAnchor.constraint(equalTo: fontContainer.topAnchor),
            fontStackView.leadingAnchor.constraint(equalTo: fontContainer.leadingAnchor),
            fontStackView.trailingAnchor.constraint(equalTo: fontContainer.trailingAnchor),
            fontStackView.bottomAnchor.constraint(equalTo: fontContainer.bottomAnchor),
            fontLabel.widthAnchor.constraint(equalToConstant: 150)
        ])
        
        stackView.addArrangedSubview(fontContainer)
        
        section.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: section.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: section.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: section.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: section.bottomAnchor)
        ])
        
        return section
    }
    
    private func getCurrentFontDescription() -> String {
        // Get current font from user defaults or use default
        let fontName = UserDefaults.standard.string(forKey: "editorFontName") ?? "SF Pro"
        let fontSize = UserDefaults.standard.double(forKey: "editorFontSize")
        let size = fontSize > 0 ? fontSize : 16.0
        return "\(fontName), \(Int(size))pt"
    }
    
    @objc private func selectFont() {
        let fontPanel = NSFontPanel.shared
        fontPanel.isEnabled = true
        fontPanel.setPanelFont(NSFont.systemFont(ofSize: 16), isMultiple: false)
        fontPanel.makeKeyAndOrderFront(self)
        
        // Set up font change notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fontChanged),
            name: NSFontPanel.fontDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func fontChanged() {
        let font = NSFontPanel.shared.convert(NSFont.systemFont(ofSize: 16))
        UserDefaults.standard.set(font.fontName, forKey: "editorFontName")
        UserDefaults.standard.set(font.pointSize, forKey: "editorFontSize")
        
        // Update UI or notify editor
        NotificationCenter.default.post(name: .editorFontChanged, object: font)
    }

    @objc private func sliderChanged(_ sender: NSSlider) {
        guard let key = sender.identifier?.rawValue else { return }
        UserDefaults.standard.set(sender.doubleValue, forKey: key)

        // Update value label
        if let valueLabel = view.viewWithTag(1) as? NSTextField,
           valueLabel.identifier?.rawValue == key + "_label" {
            valueLabel.stringValue = String(format: "%.1f", sender.doubleValue)
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let editorFontChanged = Notification.Name("editorFontChanged")
}
