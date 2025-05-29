import AppKit
import Foundation

class EditorWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        setupWindow()
    }
    
    private func setupWindow() {
        guard let window = window else { return }
        
        window.title = "Ebook Editor - Untitled"
        window.setContentSize(NSSize(width: 1200, height: 800))
        window.minSize = NSSize(width: 800, height: 600)
        window.center()
        
        // Setup the main content view
        setupMainInterface()
    }
    
    private func setupMainInterface() {
        guard let window = window,
              let contentView = window.contentView else { return }
        
        // Create main split view
        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.translatesAutoresizingMaskIntoConstraints = false
        
        // Left sidebar (Chapter Navigator)
        let sidebarView = createSidebarView()
        
        // Right main editor area
        let editorView = createEditorView()
        
        splitView.addArrangedSubview(sidebarView)
        splitView.addArrangedSubview(editorView)
        
        contentView.addSubview(splitView)
        
        NSLayoutConstraint.activate([
            splitView.topAnchor.constraint(equalTo: contentView.topAnchor),
            splitView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            splitView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Set split view proportions
        splitView.setPosition(250, ofDividerAt: 0)
    }
    
    private func createSidebarView() -> NSView {
        let sidebarContainer = NSView()
        sidebarContainer.wantsLayer = true
        sidebarContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Chapter navigator title
        let titleLabel = NSTextField(labelWithString: "Chapters")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Chapter list
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let tableView = NSTableView()
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("chapter"))
        column.title = "Chapters"
        column.width = 220
        tableView.addTableColumn(column)
        tableView.headerView = nil
        scrollView.documentView = tableView
        
        // Add chapter button
        let addButton = NSButton(title: "Add Chapter", target: nil, action: #selector(addChapter))
        addButton.bezelStyle = .rounded
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Statistics panel
        let statsView = createStatsPanel()
        
        sidebarContainer.addSubview(titleLabel)
        sidebarContainer.addSubview(scrollView)
        sidebarContainer.addSubview(addButton)
        sidebarContainer.addSubview(statsView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: sidebarContainer.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: sidebarContainer.leadingAnchor, constant: 16),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: sidebarContainer.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: sidebarContainer.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -12),
            
            addButton.leadingAnchor.constraint(equalTo: sidebarContainer.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: sidebarContainer.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: statsView.topAnchor, constant: -16),
            
            statsView.leadingAnchor.constraint(equalTo: sidebarContainer.leadingAnchor),
            statsView.trailingAnchor.constraint(equalTo: sidebarContainer.trailingAnchor),
            statsView.bottomAnchor.constraint(equalTo: sidebarContainer.bottomAnchor),
            statsView.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        return sidebarContainer
    }
    
    private func createStatsPanel() -> NSView {
        let statsContainer = NSView()
        statsContainer.wantsLayer = true
        statsContainer.layer?.backgroundColor = NSColor.separatorColor.cgColor
        
        let statsLabel = NSTextField(labelWithString: "Document Stats")
        statsLabel.font = NSFont.boldSystemFont(ofSize: 14)
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let wordCountLabel = NSTextField(labelWithString: "Words: 0")
        wordCountLabel.font = NSFont.systemFont(ofSize: 12)
        wordCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let charCountLabel = NSTextField(labelWithString: "Characters: 0")
        charCountLabel.font = NSFont.systemFont(ofSize: 12)
        charCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let readTimeLabel = NSTextField(labelWithString: "Est. Reading: 0 min")
        readTimeLabel.font = NSFont.systemFont(ofSize: 12)
        readTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statsContainer.addSubview(statsLabel)
        statsContainer.addSubview(wordCountLabel)
        statsContainer.addSubview(charCountLabel)
        statsContainer.addSubview(readTimeLabel)
        
        NSLayoutConstraint.activate([
            statsLabel.topAnchor.constraint(equalTo: statsContainer.topAnchor, constant: 12),
            statsLabel.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 16),
            
            wordCountLabel.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 8),
            wordCountLabel.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 16),
            
            charCountLabel.topAnchor.constraint(equalTo: wordCountLabel.bottomAnchor, constant: 4),
            charCountLabel.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 16),
            
            readTimeLabel.topAnchor.constraint(equalTo: charCountLabel.bottomAnchor, constant: 4),
            readTimeLabel.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 16)
        ])
        
        return statsContainer
    }
    
    private func createEditorView() -> NSView {
        let editorContainer = NSView()
        
        // Create formatting toolbar
        let toolbar = createFormattingToolbar()
        
        // Create main text editing area
        let textEditingArea = createTextEditingArea()
        
        // Create bottom status bar
        let statusBar = createStatusBar()
        
        editorContainer.addSubview(toolbar)
        editorContainer.addSubview(textEditingArea)
        editorContainer.addSubview(statusBar)
        
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: editorContainer.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: editorContainer.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: editorContainer.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 50),
            
            textEditingArea.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            textEditingArea.leadingAnchor.constraint(equalTo: editorContainer.leadingAnchor),
            textEditingArea.trailingAnchor.constraint(equalTo: editorContainer.trailingAnchor),
            textEditingArea.bottomAnchor.constraint(equalTo: statusBar.topAnchor),
            
            statusBar.leadingAnchor.constraint(equalTo: editorContainer.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: editorContainer.trailingAnchor),
            statusBar.bottomAnchor.constraint(equalTo: editorContainer.bottomAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return editorContainer
    }
    
    private func createFormattingToolbar() -> NSView {
        let toolbarContainer = NSView()
        toolbarContainer.wantsLayer = true
        toolbarContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Text formatting buttons
        let boldButton = createToolbarButton(title: "B", action: #selector(makeBold), tooltip: "Bold")
        boldButton.font = NSFont.boldSystemFont(ofSize: 14)
        
        let italicButton = createToolbarButton(title: "I", action: #selector(makeItalic), tooltip: "Italic")
        italicButton.font = NSFont.systemFont(ofSize: 14).italic()
        
        let underlineButton = createToolbarButton(title: "U", action: #selector(makeUnderline), tooltip: "Underline")
        
        // Separator
        let separator1 = createSeparator()
        
        // Paragraph formatting
        let alignLeftButton = createToolbarButton(title: "⇤", action: #selector(alignLeft), tooltip: "Align Left")
        let alignCenterButton = createToolbarButton(title: "⇿", action: #selector(alignCenter), tooltip: "Center")
        let alignRightButton = createToolbarButton(title: "⇥", action: #selector(alignRight), tooltip: "Align Right")
        
        // Separator
        let separator2 = createSeparator()
        
        // Chapter tools
        let chapterButton = createToolbarButton(title: "📖", action: #selector(insertChapter), tooltip: "Insert Chapter Break")
        let imageButton = createToolbarButton(title: "🖼️", action: #selector(insertImage), tooltip: "Insert Image")
        let footnoteButton = createToolbarButton(title: "📝", action: #selector(insertFootnote), tooltip: "Insert Footnote")
        
        // Separator
        let separator3 = createSeparator()
        
        // Format validation
        let kdpButton = createToolbarButton(title: "📚 KDP", action: #selector(validateKDP), tooltip: "Validate for KDP")
        let googleButton = createToolbarButton(title: "🔍 Google", action: #selector(validateGoogle), tooltip: "Validate for Google")
        
        // Separator
        let separator4 = createSeparator()
        
        // Audio controls
        let playButton = createToolbarButton(title: "▶️", action: #selector(playAudio), tooltip: "Read Aloud")
        let voiceButton = createToolbarButton(title: "🎙️", action: #selector(voiceSettings), tooltip: "Voice Settings")
        
        let stackView = NSStackView(views: [
            boldButton, italicButton, underlineButton, separator1,
            alignLeftButton, alignCenterButton, alignRightButton, separator2,
            chapterButton, imageButton, footnoteButton, separator3,
            kdpButton, googleButton, separator4,
            playButton, voiceButton
        ])
        stackView.orientation = .horizontal
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        toolbarContainer.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: toolbarContainer.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: toolbarContainer.leadingAnchor, constant: 16)
        ])
        
        return toolbarContainer
    }
    
    private func createToolbarButton(title: String, action: Selector, tooltip: String) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.toolTip = tooltip
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }
    
    private func createSeparator() -> NSView {
        let separator = NSView()
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            separator.widthAnchor.constraint(equalToConstant: 1),
            separator.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return separator
    }
    
    private func createTextEditingArea() -> NSView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let textView = NSTextView()
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.lineFragmentPadding = 16
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.textBackgroundColor
        
        // Add margins for better readability
        textView.textContainerInset = NSSize(width: 24, height: 24)
        
        scrollView.documentView = textView
        
        return scrollView
    }
    
    private func createStatusBar() -> NSView {
        let statusContainer = NSView()
        statusContainer.wantsLayer = true
        statusContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        let platformIndicator = NSTextField(labelWithString: "Format: Universal")
        platformIndicator.font = NSFont.systemFont(ofSize: 11)
        platformIndicator.textColor = NSColor.secondaryLabelColor
        platformIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        let validationStatus = NSTextField(labelWithString: "✅ No issues detected")
        validationStatus.font = NSFont.systemFont(ofSize: 11)
        validationStatus.textColor = NSColor.systemGreen
        validationStatus.translatesAutoresizingMaskIntoConstraints = false
        
        let currentChapter = NSTextField(labelWithString: "Chapter 1")
        currentChapter.font = NSFont.systemFont(ofSize: 11)
        currentChapter.textColor = NSColor.secondaryLabelColor
        currentChapter.translatesAutoresizingMaskIntoConstraints = false
        
        statusContainer.addSubview(platformIndicator)
        statusContainer.addSubview(validationStatus)
        statusContainer.addSubview(currentChapter)
        
        NSLayoutConstraint.activate([
            platformIndicator.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            platformIndicator.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 16),
            
            validationStatus.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            validationStatus.centerXAnchor.constraint(equalTo: statusContainer.centerXAnchor),
            
            currentChapter.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            currentChapter.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -16)
        ])
        
        return statusContainer
    }
    
    // MARK: - Action Methods
    
    @objc private func addChapter() {
        // Add new chapter logic
    }
    
    @objc private func makeBold() {
        // Bold formatting logic
    }
    
    @objc private func makeItalic() {
        // Italic formatting logic
    }
    
    @objc private func makeUnderline() {
        // Underline formatting logic
    }
    
    @objc private func alignLeft() {
        // Left alignment logic
    }
    
    @objc private func alignCenter() {
        // Center alignment logic
    }
    
    @objc private func alignRight() {
        // Right alignment logic
    }
    
    @objc private func insertChapter() {
        // Insert chapter break logic
    }
    
    @objc private func insertImage() {
        // Insert image logic
    }
    
    @objc private func insertFootnote() {
        // Insert footnote logic
    }
    
    @objc private func validateKDP() {
        // KDP validation logic
    }
    
    @objc private func validateGoogle() {
        // Google validation logic
    }
    
    @objc private func playAudio() {
        // Audio playback logic
    }
    
    @objc private func voiceSettings() {
        // Voice settings window logic
    }
}

extension NSFont {
    func italic() -> NSFont {
        return NSFontManager.shared.convert(self, toHaveTrait: .italicFontMask)
    }
}
