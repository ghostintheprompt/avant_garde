import AppKit
import Foundation

@main
class AvantGardeApp: NSApplication {

    private var preferencesWindowController: PreferencesWindowController?
    private var textToSpeech: TextToSpeech?
    
    override func finishLaunching() {
        super.finishLaunching()
        
        // Setup menu bar
        setupMenuBar()
        
        // Create and show the main editor window
        showMainEditor()
    }
    
    private func showMainEditor() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        
        // For now, create the window programmatically
        let windowController = EditorWindowController(windowNibName: nil)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Avant Garde - Professional Edition"
        window.center()
        
        windowController.window = window
        windowController.showWindow(nil)
        
        // Make this the key window
        window.makeKeyAndOrderFront(nil)
        
        // Demo content
        loadDemoContent()
    }
    
    private func loadDemoContent() {
        print("""
        
        🎨 WELCOME TO AVANT GARDE!
        ==========================
        
        ✨ THE CUTTING-EDGE AUTHORING EXPERIENCE:
        
        📝 **Rich Text Editor** with professional formatting toolbar
        📚 **Chapter Navigator** for easy book organization  
        📊 **Live Statistics** showing word count, reading time
        🎙️ **Audio Integration** for text-to-speech preview
        ⚖️ **Platform Validation** for KDP and Google compatibility
        
        🎯 **PERFECT FOR AUTHORS WHO:**
        • Write fiction or non-fiction
        • Publish on Amazon KDP and Google Play Books
        • Want professional editing tools
        • Need audio feedback for pacing and flow
        • Are tired of KDP's clunky editor limitations
        
        🚀 **MAJOR ADVANTAGES OVER KDP EDITOR:**
        
        ❌ KDP Problems → ✅ Our Solutions
        ────────────────────────────────────
        ❌ Locked formatting      → ✅ Live editing with format preview
        ❌ Can't reorganize       → ✅ Drag-and-drop chapter management  
        ❌ No audio preview       → ✅ Built-in text-to-speech with quality voices
        ❌ Platform incompatible  → ✅ One-click export to KDP AND Google
        ❌ No validation          → ✅ Real-time format checking
        ❌ Limited editing        → ✅ Full rich text with images, footnotes
        ❌ Clunky interface       → ✅ Professional, distraction-free design
        
        💡 **WORKFLOW EXAMPLE:**
        1. Write your book in the rich text editor
        2. Use chapter navigator to organize content
        3. Listen to chapters with audio playback
        4. Validate formatting for both platforms
        5. Export to KDP format with one click
        6. Export to Google Play Books format with one click
        7. Make edits and re-export instantly (no re-upload hassle!)
        
        🎵 **AUDIO FEATURES:**
        • Multiple voice options (Samantha, Alex, Ava, Tom)
        • Adjustable speed, pitch, volume
        • Chapter-by-chapter playback
        • Perfect for proofreading by ear
        • Catch dialogue pacing issues
        
        📋 **EDITOR FEATURES:**
        • Rich text formatting (bold, italic, underline)
        • Chapter breaks and organization
        • Image insertion and sizing
        • Footnote support
        • Real-time word/character counting
        • Estimated reading time calculation
        
        🔄 **CONVERSION FEATURES:**
        • KDP-optimized HTML output
        • Google Play Books EPUB generation
        • Automatic formatting adjustment
        • Platform-specific optimization
        • Maintains formatting integrity
        
        This transforms ebook creation from a frustrating technical process 
        into a smooth, professional authoring experience!
        
        Ready to revolutionize your ebook workflow? 🚀
        """)
    }
    
    // MARK: - Menu Bar Setup
    
    private func setupMenuBar() {
        let mainMenu = NSMenu()
        
        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        
        appMenu.addItem(withTitle: "About Avant Garde", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide Avant Garde", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Avant Garde", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // File menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        
        fileMenu.addItem(withTitle: "New Document", action: #selector(newDocument), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Open...", action: #selector(openDocument), keyEquivalent: "o")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Save", action: #selector(saveDocument), keyEquivalent: "s")
        fileMenu.addItem(withTitle: "Save As...", action: #selector(saveDocumentAs), keyEquivalent: "S")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Export to KDP...", action: #selector(exportToKDP), keyEquivalent: "k")
        fileMenu.addItem(withTitle: "Export to Google Play...", action: #selector(exportToGoogle), keyEquivalent: "g")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)
        
        // View menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        
        viewMenu.addItem(withTitle: "Show Sidebar", action: #selector(toggleSidebar), keyEquivalent: "s")
        viewMenu.addItem(withTitle: "Show Statistics", action: #selector(toggleStatistics), keyEquivalent: "i")
        viewMenu.addItem(NSMenuItem.separator())
        
        // Color themes submenu
        let themesMenuItem = NSMenuItem(title: "Color Themes", action: nil, keyEquivalent: "")
        let themesMenu = NSMenu()
        
        for theme in ColorThemeManager.WritingTheme.allCases {
            let themeItem = NSMenuItem(title: theme.rawValue, action: #selector(selectTheme(_:)), keyEquivalent: "")
            themeItem.representedObject = theme
            themesMenu.addItem(themeItem)
        }
        
        themesMenuItem.submenu = themesMenu
        viewMenu.addItem(themesMenuItem)
        
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)
        
        // Audio menu
        let audioMenuItem = NSMenuItem()
        let audioMenu = NSMenu(title: "Audio")
        
        audioMenu.addItem(withTitle: "Play Current Chapter", action: #selector(playCurrentChapter), keyEquivalent: " ")
        audioMenu.addItem(withTitle: "Pause", action: #selector(pauseAudio), keyEquivalent: "p")
        audioMenu.addItem(withTitle: "Stop", action: #selector(stopAudio), keyEquivalent: ".")
        audioMenu.addItem(NSMenuItem.separator())
        audioMenu.addItem(withTitle: "Voice Settings...", action: #selector(showVoiceSettings), keyEquivalent: "v")
        
        audioMenuItem.submenu = audioMenu
        mainMenu.addItem(audioMenuItem)
        
        // Help menu
        let helpMenuItem = NSMenuItem()
        let helpMenu = NSMenu(title: "Help")
        
        helpMenu.addItem(withTitle: "Avant Garde Help", action: #selector(showHelp), keyEquivalent: "?")
        helpMenu.addItem(withTitle: "Color Psychology Guide", action: #selector(showColorGuide), keyEquivalent: "")
        helpMenu.addItem(withTitle: "Voice Setup Guide", action: #selector(showVoiceGuide), keyEquivalent: "")
        helpMenu.addItem(NSMenuItem.separator())
        helpMenu.addItem(withTitle: "Report an Issue", action: #selector(reportIssue), keyEquivalent: "")
        
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)
        
        NSApp.mainMenu = mainMenu
    }
    
    // MARK: - Menu Actions
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Avant Garde - Professional Authoring Tool"
        alert.informativeText = """
        Professional ebook authoring and conversion tool
        
        Features:
        • Rich text editor with chapter management
        • Color psychology-based themes
        • High-quality text-to-speech audio
        • One-click KDP and Google Play export
        • Real-time format validation
        
        Built for authors who demand better tools.
        """
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
    }
    
    @objc private func newDocument() {
        let document = EbookDocument()
        let windowController = EditorWindowController(document: document)
        document.addWindowController(windowController)
        windowController.showWindow(nil)
    }

    @objc private func openDocument() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.json, .data]
        openPanel.message = "Choose an Avant Garde document to open"

        openPanel.begin { response in
            guard response == .OK, let url = openPanel.url else { return }

            do {
                let data = try Data(contentsOf: url)
                let document = EbookDocument()
                try document.read(from: data, ofType: "AvantGardeDocument")

                let windowController = EditorWindowController(document: document)
                document.addWindowController(windowController)
                windowController.showWindow(nil)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Failed to Open Document"
                alert.informativeText = "Could not open the selected document: \(error.localizedDescription)"
                alert.alertStyle = .critical
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }

    @objc private func saveDocument() {
        guard let mainWindow = NSApp.mainWindow,
              let windowController = mainWindow.windowController as? EditorWindowController,
              let document = windowController.document as? EbookDocument else {
            showNoDocumentAlert()
            return
        }

        if let fileURL = document.fileURL {
            saveDocument(document, to: fileURL)
        } else {
            saveDocumentAs()
        }
    }

    @objc private func saveDocumentAs() {
        guard let mainWindow = NSApp.mainWindow,
              let windowController = mainWindow.windowController as? EditorWindowController,
              let document = windowController.document as? EbookDocument else {
            showNoDocumentAlert()
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = document.metadata.title.isEmpty ? "Untitled.avantgarde" : "\(document.metadata.title).avantgarde"
        savePanel.message = "Save your Avant Garde document"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            self.saveDocument(document, to: url)
        }
    }

    private func saveDocument(_ document: EbookDocument, to url: URL) {
        do {
            let data = try document.data(ofType: "AvantGardeDocument")
            try data.write(to: url)
            document.fileURL = url

            let alert = NSAlert()
            alert.messageText = "Document Saved"
            alert.informativeText = "Your document has been saved successfully."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Save Failed"
            alert.informativeText = "Could not save the document: \(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func showNoDocumentAlert() {
        let alert = NSAlert()
        alert.messageText = "No Document Open"
        alert.informativeText = "Please create or open a document first."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func exportToKDP() {
        guard let mainWindow = NSApp.mainWindow,
              let windowController = mainWindow.windowController as? EditorWindowController,
              let document = windowController.document as? EbookDocument else {
            showNoDocumentAlert()
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.html]
        savePanel.nameFieldStringValue = document.metadata.title.isEmpty ? "book.html" : "\(document.metadata.title).html"
        savePanel.message = "Export to KDP HTML format"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            do {
                let kdpData = try document.exportToKDP()
                try kdpData.write(to: url)

                let alert = NSAlert()
                alert.messageText = "KDP Export Successful"
                alert.informativeText = "Your book has been exported to KDP HTML format. You can now upload it to Amazon KDP."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            } catch {
                let alert = NSAlert()
                alert.messageText = "Export Failed"
                alert.informativeText = "Could not export to KDP format: \(error.localizedDescription)"
                alert.alertStyle = .critical
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }

    @objc private func exportToGoogle() {
        guard let mainWindow = NSApp.mainWindow,
              let windowController = mainWindow.windowController as? EditorWindowController,
              let document = windowController.document as? EbookDocument else {
            showNoDocumentAlert()
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.epub]
        savePanel.nameFieldStringValue = document.metadata.title.isEmpty ? "book.epub" : "\(document.metadata.title).epub"
        savePanel.message = "Export to Google Play Books EPUB format"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            do {
                let googleData = try document.exportToGoogle()
                try googleData.write(to: url)

                let alert = NSAlert()
                alert.messageText = "Google Play Export Successful"
                alert.informativeText = "Your book has been exported to EPUB format. You can now upload it to Google Play Books."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            } catch {
                let alert = NSAlert()
                alert.messageText = "Export Failed"
                alert.informativeText = "Could not export to Google Play format: \(error.localizedDescription)"
                alert.alertStyle = .critical
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
    
    @objc private func toggleSidebar() {
        guard let mainWindow = NSApp.mainWindow,
              let windowController = mainWindow.windowController as? EditorWindowController else {
            return
        }
        windowController.toggleSidebar(nil)
    }

    @objc private func toggleStatistics() {
        guard let mainWindow = NSApp.mainWindow,
              let windowController = mainWindow.windowController as? EditorWindowController else {
            return
        }
        windowController.toggleStatistics()
    }
    
    @objc private func selectTheme(_ sender: NSMenuItem) {
        guard let theme = sender.representedObject as? ColorThemeManager.WritingTheme else { return }
        ColorThemeManager.shared.applyTheme(theme)
    }
    
    @objc private func playCurrentChapter() {
        guard let mainWindow = NSApp.mainWindow,
              let windowController = mainWindow.windowController as? EditorWindowController,
              let document = windowController.document as? EbookDocument else {
            showNoDocumentAlert()
            return
        }

        if textToSpeech == nil {
            textToSpeech = TextToSpeech()
        }

        // For now, speak the entire document
        // TODO: Implement current chapter detection
        if let firstChapter = document.chapters.first {
            textToSpeech?.speakChapter(firstChapter)
        }
    }

    @objc private func pauseAudio() {
        guard let tts = textToSpeech else {
            let alert = NSAlert()
            alert.messageText = "No Audio Playing"
            alert.informativeText = "There is no audio currently playing."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        if tts.isSpeaking {
            tts.pauseSpeaking()
        } else if tts.isPaused {
            tts.continueSpeaking()
        }
    }

    @objc private func stopAudio() {
        guard let tts = textToSpeech else { return }
        tts.stopSpeaking()
    }
    
    @objc private func showVoiceSettings() {
        // Open preferences to voice tab
        showPreferences()
        // TODO: Navigate to voice tab
    }
    
    @objc private func showHelp() {
        // TODO: Show help window
        print("Help requested")
    }
    
    @objc private func showColorGuide() {
        let alert = NSAlert()
        alert.messageText = "Color Psychology for Writers"
        alert.informativeText = """
        🎨 Color Psychology in Writing Apps
        
        Different colors affect your mind differently:
        
        🔵 Blue (Focused Flow): Enhances concentration and reduces mental fatigue
        🟠 Orange (Creative Burst): Stimulates imagination and innovative thinking
        🟢 Green (Zen Garden): Promotes relaxation and steady writing flow
        🔴 Red (Power Writing): Increases alertness and writing speed
        🟣 Purple (Mystery): Creates atmospheric tension for dramatic writing
        
        Try different themes and notice how they affect your writing mood!
        """
        alert.addButton(withTitle: "Open Theme Selector")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            showPreferences()
        }
    }
    
    @objc private func showVoiceGuide() {
        let alert = NSAlert()
        alert.messageText = "Voice Setup Guide"
        alert.informativeText = """
        🎙️ Setting Up High-Quality Voices
        
        For the best text-to-speech experience:
        
        1. Open System Preferences → Accessibility → Spoken Content
        2. Click "System Voice" dropdown
        3. Download enhanced voices like:
           • Samantha (Premium)
           • Alex (Enhanced)
           • Ava (Premium)
           • Tom (Enhanced)
        
        Premium voices sound much more natural and are perfect for proofreading your work!
        """
        alert.addButton(withTitle: "Open Voice Settings")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            showPreferences()
        }
    }
    
    @objc private func reportIssue() {
        // TODO: Open issue reporting
        print("Report issue requested")
    }
}

// If running as a standalone app
if ProcessInfo.processInfo.arguments.contains("--demo") {
    let app = EbookConverterApp.shared
    app.run()
}
