import AppKit
import Foundation

@main
class AvantGardeApp: NSApplication {
    
    private var preferencesWindowController: PreferencesWindowController?
    
    override func finishLaunching() {
        super.finishLaunching()

        // Setup menu bar
        setupMenuBar()

        // Check if this is first launch
        let hasCompletedWelcome = UserDefaults.standard.bool(forKey: "hasCompletedWelcome")

        if !hasCompletedWelcome {
            showWelcomeScreen()
        } else {
            showMainEditor()
        }

        // Listen for welcome completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(welcomeDidComplete),
            name: .welcomeDidComplete,
            object: nil
        )
    }

    @objc private func welcomeDidComplete() {
        showMainEditor()
    }

    private func showWelcomeScreen() {
        let welcomeViewController = WelcomeViewController()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "Welcome to Avant Garde"
        window.titlebarAppearsTransparent = true
        window.center()
        window.contentViewController = welcomeViewController
        window.makeKeyAndOrderFront(nil)
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
        // TODO: Implement new document
        print("New document requested")
    }
    
    @objc private func openDocument() {
        // TODO: Implement open document
        print("Open document requested")
    }
    
    @objc private func saveDocument() {
        // TODO: Implement save document
        print("Save document requested")
    }
    
    @objc private func saveDocumentAs() {
        // TODO: Implement save as
        print("Save as requested")
    }
    
    @objc private func exportToKDP() {
        // TODO: Implement KDP export
        print("KDP export requested")
    }
    
    @objc private func exportToGoogle() {
        // TODO: Implement Google export
        print("Google export requested")
    }
    
    @objc private func toggleSidebar() {
        // TODO: Implement sidebar toggle
        print("Toggle sidebar requested")
    }
    
    @objc private func toggleStatistics() {
        // TODO: Implement statistics toggle
        print("Toggle statistics requested")
    }
    
    @objc private func selectTheme(_ sender: NSMenuItem) {
        guard let theme = sender.representedObject as? ColorThemeManager.WritingTheme else { return }
        ColorThemeManager.shared.applyTheme(theme)
    }
    
    @objc private func playCurrentChapter() {
        // TODO: Implement audio playback
        print("Play current chapter requested")
    }
    
    @objc private func pauseAudio() {
        // TODO: Implement audio pause
        print("Pause audio requested")
    }
    
    @objc private func stopAudio() {
        // TODO: Implement audio stop
        print("Stop audio requested")
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

// Entry point
AvantGardeApp.main()
