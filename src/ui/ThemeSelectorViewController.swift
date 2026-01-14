import AppKit
import Foundation

/// Beautiful theme selection interface showcasing color psychology benefits
class ThemeSelectorViewController: NSViewController {

    // UI Elements - created programmatically
    private var scrollView: NSScrollView!
    private var themeGridView: NSView!
    private var recommendationView: NSView!
    private var writingTypePopup: NSPopUpButton!
    private var timeBasedButton: NSButton!
    private var previewTextView: NSTextView!
    private var psychologyLabel: NSTextField!
    private var benefitsLabel: NSTextField!

    private let themeManager = ColorThemeManager.shared
    private var themeCards: [ThemeCardView] = []
    private var selectedTheme: ColorThemeManager.WritingTheme = .focused
    private var timeBasedUpdateTimer: Timer?

    override func loadView() {
        // Create the main view
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 700))
        createUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupThemeGrid()
        setupRecommendations()
        setupPreview()
        updateThemeSelection()
    }

    private func createUI() {
        // Title
        let titleLabel = NSTextField(labelWithString: "Choose Your Writing Theme")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 20)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Recommendation view
        recommendationView = NSView(frame: .zero)
        recommendationView.wantsLayer = true
        recommendationView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        recommendationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recommendationView)

        // Writing type label
        let typeLabel = NSTextField(labelWithString: "Writing Type:")
        typeLabel.isEditable = false
        typeLabel.isBordered = false
        typeLabel.backgroundColor = .clear
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        recommendationView.addSubview(typeLabel)

        // Writing type popup
        writingTypePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        writingTypePopup.translatesAutoresizingMaskIntoConstraints = false
        recommendationView.addSubview(writingTypePopup)

        // Time-based button
        timeBasedButton = NSButton(title: "Use Time-Based Theme", target: nil, action: nil)
        timeBasedButton.bezelStyle = .rounded
        timeBasedButton.translatesAutoresizingMaskIntoConstraints = false
        recommendationView.addSubview(timeBasedButton)

        // Scroll view for theme grid
        scrollView = NSScrollView(frame: .zero)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Theme grid view
        themeGridView = NSView(frame: .zero)
        scrollView.documentView = themeGridView

        // Preview section
        let previewContainer = NSView(frame: .zero)
        previewContainer.wantsLayer = true
        previewContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewContainer)

        let previewTitle = NSTextField(labelWithString: "Preview")
        previewTitle.font = NSFont.boldSystemFont(ofSize: 14)
        previewTitle.isEditable = false
        previewTitle.isBordered = false
        previewTitle.backgroundColor = .clear
        previewTitle.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(previewTitle)

        // Preview text view
        let previewScrollView = NSScrollView(frame: .zero)
        previewScrollView.hasVerticalScroller = true
        previewScrollView.borderType = .bezelBorder
        previewScrollView.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(previewScrollView)

        previewTextView = NSTextView(frame: .zero)
        previewTextView.isEditable = false
        previewScrollView.documentView = previewTextView

        // Psychology labels
        psychologyLabel = NSTextField(labelWithString: "Select a theme to see its benefits")
        psychologyLabel.isEditable = false
        psychologyLabel.isBordered = false
        psychologyLabel.backgroundColor = .clear
        psychologyLabel.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(psychologyLabel)

        benefitsLabel = NSTextField(labelWithString: "")
        benefitsLabel.isEditable = false
        benefitsLabel.isBordered = false
        benefitsLabel.backgroundColor = .clear
        benefitsLabel.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(benefitsLabel)

        // Set up constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            recommendationView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            recommendationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            recommendationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            recommendationView.heightAnchor.constraint(equalToConstant: 60),

            typeLabel.leadingAnchor.constraint(equalTo: recommendationView.leadingAnchor, constant: 10),
            typeLabel.centerYAnchor.constraint(equalTo: recommendationView.centerYAnchor),

            writingTypePopup.leadingAnchor.constraint(equalTo: typeLabel.trailingAnchor, constant: 10),
            writingTypePopup.centerYAnchor.constraint(equalTo: recommendationView.centerYAnchor),
            writingTypePopup.widthAnchor.constraint(equalToConstant: 180),

            timeBasedButton.trailingAnchor.constraint(equalTo: recommendationView.trailingAnchor, constant: -10),
            timeBasedButton.centerYAnchor.constraint(equalTo: recommendationView.centerYAnchor),

            scrollView.topAnchor.constraint(equalTo: recommendationView.bottomAnchor, constant: 15),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.heightAnchor.constraint(equalToConstant: 350),

            previewContainer.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 15),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            previewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),

            previewTitle.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 10),
            previewTitle.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 10),

            previewScrollView.topAnchor.constraint(equalTo: previewTitle.bottomAnchor, constant: 5),
            previewScrollView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 10),
            previewScrollView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -10),
            previewScrollView.heightAnchor.constraint(equalToConstant: 120),

            psychologyLabel.topAnchor.constraint(equalTo: previewScrollView.bottomAnchor, constant: 10),
            psychologyLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 10),
            psychologyLabel.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -10),

            benefitsLabel.topAnchor.constraint(equalTo: psychologyLabel.bottomAnchor, constant: 5),
            benefitsLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 10),
            benefitsLabel.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -10)
        ])
    }
    
    // MARK: - Theme Grid Setup
    
    private func setupThemeGrid() {
        themeGridView.subviews.removeAll()
        themeCards.removeAll()
        
        let themes = ColorThemeManager.WritingTheme.allCases
        let columns = 3
        let rows = (themes.count + columns - 1) / columns
        let cardWidth: CGFloat = 280
        let cardHeight: CGFloat = 180
        let spacing: CGFloat = 20
        
        // Calculate total grid size
        let totalWidth = CGFloat(columns) * cardWidth + CGFloat(columns - 1) * spacing
        let totalHeight = CGFloat(rows) * cardHeight + CGFloat(rows - 1) * spacing
        
        // Set frame for grid view
        themeGridView.frame = NSRect(x: 0, y: 0, width: totalWidth, height: totalHeight)
        
        for (index, theme) in themes.enumerated() {
            let row = index / columns
            let col = index % columns
            
            let x = CGFloat(col) * (cardWidth + spacing)
            let y = totalHeight - CGFloat(row + 1) * cardHeight - CGFloat(row) * spacing
            
            let cardFrame = NSRect(x: x, y: y, width: cardWidth, height: cardHeight)
            let card = ThemeCardView(frame: cardFrame, theme: theme)
            
            card.onSelect = { [weak self] selectedTheme in
                self?.selectTheme(selectedTheme)
            }
            
            themeGridView.addSubview(card)
            themeCards.append(card)
        }
        
        // Update scroll view content size
        scrollView.documentView?.frame = themeGridView.frame
    }
    
    // MARK: - Recommendations Setup
    
    private func setupRecommendations() {
        // Setup writing type popup
        writingTypePopup.removeAllItems()
        for type in WritingType.allCases {
            writingTypePopup.addItem(withTitle: type.rawValue)
        }
        
        writingTypePopup.target = self
        writingTypePopup.action = #selector(writingTypeChanged)
        
        // Setup time-based button
        timeBasedButton.target = self
        timeBasedButton.action = #selector(useTimeBasedTheme)
        updateTimeBasedButton()
        
        // Auto-update time-based recommendations every minute
        timeBasedUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateTimeBasedButton()
        }
    }
    
    private func setupPreview() {
        let sampleText = """
        The old man sat by the window, watching the rain cascade down the glass in silver rivulets. Each droplet seemed to carry with it a memory, a fragment of the past that he had thought long buried. 
        
        Outside, the world moved on—cars splashing through puddles, people hurrying under umbrellas, life continuing its relentless march forward. But here, in this quiet room, time felt suspended, held in the gentle embrace of nostalgia and possibility.
        
        He picked up his pen and began to write, the words flowing like the rain itself, each sentence a small act of rebellion against the silence that had held him captive for far too long.
        """
        
        previewTextView.string = sampleText
        previewTextView.font = NSFont.systemFont(ofSize: 16, weight: .regular)
        previewTextView.isEditable = false
        
        // Apply current theme to preview
        applyThemeToPreview()
    }
    
    // MARK: - Theme Selection
    
    private func selectTheme(_ theme: ColorThemeManager.WritingTheme) {
        selectedTheme = theme
        updateThemeSelection()
        updatePsychologyInfo()
        applyThemeToPreview()
        
        // Apply theme to main app
        themeManager.applyTheme(theme)
        
        // Animate selection
        animateThemeSelection()
    }
    
    private func updateThemeSelection() {
        for card in themeCards {
            card.isSelected = (card.theme == selectedTheme)
        }
    }
    
    private func updatePsychologyInfo() {
        psychologyLabel.stringValue = selectedTheme.description
        benefitsLabel.stringValue = "✨ " + selectedTheme.psychologyEffect
        
        // Style the labels
        psychologyLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        psychologyLabel.textColor = selectedTheme.colors.text
        
        benefitsLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        benefitsLabel.textColor = selectedTheme.colors.accent
    }
    
    private func applyThemeToPreview() {
        let colors = selectedTheme.colors
        
        previewTextView.backgroundColor = colors.background
        previewTextView.textColor = colors.text
        previewTextView.insertionPointColor = colors.cursorColor
        
        // Add subtle border
        previewTextView.layer?.borderColor = colors.accent.cgColor
        previewTextView.layer?.borderWidth = 1.0
        previewTextView.layer?.cornerRadius = 8.0
    }
    
    private func animateThemeSelection() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            view.needsDisplay = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func writingTypeChanged() {
        guard let selectedType = WritingType.allCases.first(where: { 
            $0.rawValue == writingTypePopup.selectedItem?.title 
        }) else { return }
        
        let recommendedTheme = themeManager.recommendThemeForWritingType(selectedType)
        selectTheme(recommendedTheme)
        
        // Show recommendation animation
        showRecommendationTooltip(for: selectedType, theme: recommendedTheme)
    }
    
    @objc private func useTimeBasedTheme() {
        let timeTheme = themeManager.getThemeForTimeOfDay()
        selectTheme(timeTheme)
        
        // Show time-based recommendation
        showTimeBasedTooltip(theme: timeTheme)
    }
    
    private func updateTimeBasedButton() {
        let currentTheme = themeManager.getThemeForTimeOfDay()
        let hour = Calendar.current.component(.hour, from: Date())
        
        var timeDescription = ""
        switch hour {
        case 6...9: timeDescription = "Morning Energy"
        case 10...14: timeDescription = "Peak Focus"
        case 15...18: timeDescription = "Creative Hours"
        case 19...21: timeDescription = "Evening Calm"
        default: timeDescription = "Night Writing"
        }
        
        timeBasedButton.title = "Use \(timeDescription) Theme (\(currentTheme.rawValue))"
    }
    
    // MARK: - Tooltips and Animations
    
    private func showRecommendationTooltip(for type: WritingType, theme: ColorThemeManager.WritingTheme) {
        let tooltip = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 80))
        tooltip.wantsLayer = true
        tooltip.layer?.backgroundColor = theme.colors.accent.cgColor
        tooltip.layer?.cornerRadius = 8.0
        
        let label = NSTextField(labelWithString: "Perfect for \(type.rawValue)!\n\(theme.description)")
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = NSColor.white
        label.frame = tooltip.bounds.insetBy(dx: 10, dy: 10)
        tooltip.addSubview(label)
        
        view.addSubview(tooltip)
        tooltip.center = writingTypePopup.center
        
        // Animate tooltip
        tooltip.alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            tooltip.animator().alphaValue = 1.0
        } completionHandler: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    tooltip.animator().alphaValue = 0.0
                } completionHandler: {
                    tooltip.removeFromSuperview()
                }
            }
        }
    }
    
    private func showTimeBasedTooltip(theme: ColorThemeManager.WritingTheme) {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let currentTime = timeFormatter.string(from: Date())
        
        let message = "Perfect timing! \(theme.rawValue) theme is optimal for writing at \(currentTime)"
        
        let alert = NSAlert()
        alert.messageText = "Time-Based Theme Applied"
        alert.informativeText = message
        alert.addButton(withTitle: "Great!")
        alert.alertStyle = .informational
        alert.runModal()
    }

    deinit {
        timeBasedUpdateTimer?.invalidate()
        timeBasedUpdateTimer = nil
    }
}

// MARK: - Theme Card View

class ThemeCardView: NSView {
    
    let theme: ColorThemeManager.WritingTheme
    var onSelect: ((ColorThemeManager.WritingTheme) -> Void)?
    var isSelected: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    private let titleLabel = NSTextField()
    private let descriptionLabel = NSTextField()
    private let benefitsLabel = NSTextField()
    private let colorPreview = NSView()
    private let selectButton = NSButton()
    
    init(frame: NSRect, theme: ColorThemeManager.WritingTheme) {
        self.theme = theme
        super.init(frame: frame)
        setupCard()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCard() {
        wantsLayer = true
        layer?.cornerRadius = 12.0
        layer?.borderWidth = 2.0
        
        // Color preview circle
        colorPreview.wantsLayer = true
        colorPreview.layer?.cornerRadius = 20.0
        colorPreview.frame = NSRect(x: 20, y: frame.height - 60, width: 40, height: 40)
        colorPreview.layer?.backgroundColor = theme.colors.accent.cgColor
        addSubview(colorPreview)
        
        // Title
        titleLabel.stringValue = theme.rawValue
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = theme.colors.text
        titleLabel.isBezeled = false
        titleLabel.isEditable = false
        titleLabel.backgroundColor = NSColor.clear
        titleLabel.frame = NSRect(x: 75, y: frame.height - 50, width: frame.width - 95, height: 20)
        addSubview(titleLabel)
        
        // Description
        descriptionLabel.stringValue = theme.description
        descriptionLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        descriptionLabel.textColor = theme.colors.text.withAlphaComponent(0.8)
        descriptionLabel.isBezeled = false
        descriptionLabel.isEditable = false
        descriptionLabel.backgroundColor = NSColor.clear
        descriptionLabel.frame = NSRect(x: 20, y: frame.height - 110, width: frame.width - 40, height: 40)
        descriptionLabel.maximumNumberOfLines = 2
        descriptionLabel.lineBreakMode = .byWordWrapping
        addSubview(descriptionLabel)
        
        // Benefits
        benefitsLabel.stringValue = "✨ " + theme.psychologyEffect
        benefitsLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        benefitsLabel.textColor = theme.colors.accent
        benefitsLabel.isBezeled = false
        benefitsLabel.isEditable = false
        benefitsLabel.backgroundColor = NSColor.clear
        benefitsLabel.frame = NSRect(x: 20, y: 30, width: frame.width - 40, height: 30)
        benefitsLabel.maximumNumberOfLines = 2
        benefitsLabel.lineBreakMode = .byWordWrapping
        addSubview(benefitsLabel)
        
        // Select button
        selectButton.title = "Apply Theme"
        selectButton.bezelStyle = .rounded
        selectButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        selectButton.frame = NSRect(x: 20, y: 8, width: frame.width - 40, height: 24)
        selectButton.target = self
        selectButton.action = #selector(selectButtonClicked)
        addSubview(selectButton)
        
        updateAppearance()
        
        // Add hover effect
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        ))
    }
    
    private func updateAppearance() {
        let colors = theme.colors
        layer?.backgroundColor = colors.background.cgColor
        layer?.borderColor = isSelected ? colors.accent.cgColor : colors.text.withAlphaComponent(0.2).cgColor
        layer?.borderWidth = isSelected ? 3.0 : 1.0
        
        selectButton.contentTintColor = colors.accent
        selectButton.title = isSelected ? "✓ Applied" : "Apply Theme"
        selectButton.isEnabled = !isSelected
    }
    
    @objc private func selectButtonClicked() {
        onSelect?(theme)
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            layer?.shadowColor = theme.colors.accent.cgColor
            layer?.shadowOpacity = 0.3
            layer?.shadowOffset = NSSize(width: 0, height: 5)
            layer?.shadowRadius = 10.0
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            layer?.shadowOpacity = 0.0
        }
    }
}

// MARK: - Extensions

extension NSView {
    var center: NSPoint {
        get {
            return NSPoint(x: frame.midX, y: frame.midY)
        }
        set {
            frame.origin = NSPoint(x: newValue.x - frame.width / 2, y: newValue.y - frame.height / 2)
        }
    }
}
