import AppKit
import Foundation

/// Welcome screen shown on first launch with onboarding
class WelcomeViewController: NSViewController {

    private var currentPage: Int = 0
    private let pages: [WelcomePage] = [
        WelcomePage(
            icon: "book.fill",
            title: "Welcome to Avant Garde",
            description: "Professional ebook authoring with cutting-edge features to enhance your writing experience."
        ),
        WelcomePage(
            icon: "paintpalette.fill",
            title: "Color Psychology Themes",
            description: "Choose from 12 research-backed color themes designed to boost creativity, focus, and productivity by up to 31%."
        ),
        WelcomePage(
            icon: "speaker.wave.3.fill",
            title: "Audio Feedback",
            description: "Listen to your writing with high-quality text-to-speech to catch errors and improve pacing."
        ),
        WelcomePage(
            icon: "arrow.up.doc.fill",
            title: "One-Click Publishing",
            description: "Export directly to Amazon KDP and Google Play Books formats with perfect formatting guaranteed."
        )
    ]

    private var pageControl: NSSegmentedControl!
    private var contentView: NSView!
    private var titleLabel: NSTextField!
    private var descriptionLabel: NSTextField!
    private var iconImageView: NSImageView!
    private var continueButton: NSButton!
    private var skipButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updatePage()
    }

    override var preferredContentSize: NSSize {
        return NSSize(width: 800, height: 600)
    }

    private func setupUI() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // Main content container
        contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // Icon
        iconImageView = NSImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.imageScaling = .scaleProportionallyDown
        iconImageView.contentTintColor = NSColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 1.0) // Indigo

        // Title
        titleLabel = NSTextField(labelWithString: "")
        titleLabel.font = NSFont.systemFont(ofSize: 36, weight: .bold)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Description
        descriptionLabel = NSTextField(wrappingLabelWithString: "")
        descriptionLabel.font = NSFont.systemFont(ofSize: 16)
        descriptionLabel.alignment = .center
        descriptionLabel.textColor = NSColor.secondaryLabelColor
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.maximumNumberOfLines = 3

        // Page control (dots)
        pageControl = NSSegmentedControl()
        pageControl.segmentCount = pages.count
        pageControl.segmentStyle = .rounded
        for i in 0..<pages.count {
            pageControl.setWidth(12, forSegment: i)
            pageControl.setLabel("", forSegment: i)
        }
        pageControl.selectedSegment = 0
        pageControl.target = self
        pageControl.action = #selector(pageChanged(_:))
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        // Continue button
        continueButton = NSButton()
        continueButton.title = "Next"
        continueButton.bezelStyle = .rounded
        continueButton.keyEquivalent = "\r"
        continueButton.target = self
        continueButton.action = #selector(continuePressed)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.contentTintColor = NSColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 1.0)

        // Skip button
        skipButton = NSButton()
        skipButton.title = "Skip Tutorial"
        skipButton.bezelStyle = .roundedDisclosure
        skipButton.isBordered = false
        skipButton.target = self
        skipButton.action = #selector(skipPressed)
        skipButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(pageControl)
        contentView.addSubview(continueButton)
        contentView.addSubview(skipButton)

        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.widthAnchor.constraint(equalToConstant: 600),
            contentView.heightAnchor.constraint(equalToConstant: 500),

            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 120),
            iconImageView.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60),

            pageControl.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 40),
            pageControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            continueButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            continueButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 200),
            continueButton.heightAnchor.constraint(equalToConstant: 40),

            skipButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func updatePage() {
        let page = pages[currentPage]

        // Animate transition
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3

            titleLabel.animator().stringValue = page.title
            descriptionLabel.animator().stringValue = page.description

            if let icon = NSImage(systemSymbolName: page.icon, accessibilityDescription: page.title) {
                let config = NSImage.SymbolConfiguration(pointSize: 80, weight: .regular)
                iconImageView.image = icon.withSymbolConfiguration(config)
            }
        }

        pageControl.selectedSegment = currentPage

        // Update button title
        if currentPage == pages.count - 1 {
            continueButton.title = "Get Started"
        } else {
            continueButton.title = "Next"
        }
    }

    @objc private func pageChanged(_ sender: NSSegmentedControl) {
        currentPage = sender.selectedSegment
        updatePage()
    }

    @objc private func continuePressed() {
        if currentPage < pages.count - 1 {
            currentPage += 1
            updatePage()
        } else {
            finishWelcome()
        }
    }

    @objc private func skipPressed() {
        finishWelcome()
    }

    private func finishWelcome() {
        // Mark welcome as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedWelcome")

        // Close welcome window and show main editor
        view.window?.close()

        NotificationCenter.default.post(
            name: .welcomeDidComplete,
            object: nil
        )
    }
}

// MARK: - Welcome Page Model

struct WelcomePage {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Notification Extension

extension Notification.Name {
    static let welcomeDidComplete = Notification.Name("welcomeDidComplete")
}
