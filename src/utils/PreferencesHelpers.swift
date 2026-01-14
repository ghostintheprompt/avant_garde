import AppKit
import Foundation

/// Shared utility methods for creating preference UI controls
/// Eliminates code duplication across preference view controllers
enum PreferencesHelpers {

    // MARK: - Section Creation

    /// Creates a titled section containing multiple controls
    /// - Parameters:
    ///   - title: The section title
    ///   - controls: Array of NSView controls to add to the section
    /// - Returns: NSView containing the section
    static func createSection(title: String, controls: [NSView]) -> NSView {
        let section = NSView()
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Section title
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        stackView.addArrangedSubview(titleLabel)

        // Add controls
        for control in controls {
            stackView.addArrangedSubview(control)
        }

        section.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: section.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: section.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: section.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: section.bottomAnchor)
        ])

        return section
    }

    // MARK: - Control Creation

    /// Creates a checkbox bound to UserDefaults
    /// - Parameters:
    ///   - title: The checkbox title
    ///   - key: The UserDefaults key
    ///   - target: The action target
    ///   - action: The action selector
    /// - Returns: NSButton configured as a checkbox
    static func createCheckbox(title: String, key: String, target: AnyObject?, action: Selector) -> NSButton {
        let checkbox = NSButton(checkboxWithTitle: title, target: target, action: action)
        checkbox.state = UserDefaults.standard.bool(forKey: key) ? .on : .off
        checkbox.identifier = NSUserInterfaceItemIdentifier(key)
        return checkbox
    }

    /// Creates a labeled text field bound to UserDefaults
    /// - Parameters:
    ///   - label: The label text
    ///   - key: The UserDefaults key
    ///   - placeholder: Placeholder text for the field
    ///   - target: The action target
    ///   - action: The action selector
    /// - Returns: NSView containing the label and text field
    static func createTextField(label: String, key: String, placeholder: String, target: AnyObject?, action: Selector) -> NSView {
        let container = NSView()
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let labelField = NSTextField(labelWithString: label)
        labelField.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let textField = NSTextField()
        textField.stringValue = UserDefaults.standard.string(forKey: key) ?? ""
        textField.placeholderString = placeholder
        textField.identifier = NSUserInterfaceItemIdentifier(key)
        textField.target = target
        textField.action = action

        stackView.addArrangedSubview(labelField)
        stackView.addArrangedSubview(textField)

        container.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            labelField.widthAnchor.constraint(equalToConstant: 150)
        ])

        return container
    }

    /// Creates a labeled slider bound to UserDefaults
    /// - Parameters:
    ///   - label: The label text
    ///   - key: The UserDefaults key
    ///   - min: Minimum slider value
    ///   - max: Maximum slider value
    ///   - target: The action target
    ///   - action: The action selector
    /// - Returns: NSView containing the label, slider, and value display
    static func createSlider(label: String, key: String, min: Double, max: Double, target: AnyObject?, action: Selector) -> NSView {
        let container = NSView()
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let labelField = NSTextField(labelWithString: label)
        labelField.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let slider = NSSlider()
        slider.minValue = min
        slider.maxValue = max
        slider.doubleValue = UserDefaults.standard.double(forKey: key)
        if slider.doubleValue == 0 {
            slider.doubleValue = min
        }
        slider.identifier = NSUserInterfaceItemIdentifier(key)
        slider.target = target
        slider.action = action

        let valueLabel = NSTextField(labelWithString: String(format: "%.1f", slider.doubleValue))
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        valueLabel.identifier = NSUserInterfaceItemIdentifier(key + "_label")

        stackView.addArrangedSubview(labelField)
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(valueLabel)

        container.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            labelField.widthAnchor.constraint(equalToConstant: 150),
            valueLabel.widthAnchor.constraint(equalToConstant: 40)
        ])

        return container
    }

    /// Creates a labeled popup button
    /// - Parameters:
    ///   - label: The label text
    ///   - items: Array of item titles for the popup
    ///   - key: The UserDefaults key
    ///   - target: The action target
    ///   - action: The action selector
    /// - Returns: NSView containing the label and popup button
    static func createPopup(label: String, items: [String], key: String, target: AnyObject?, action: Selector) -> NSView {
        let container = NSView()
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let labelField = NSTextField(labelWithString: label)
        labelField.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.addItems(withTitles: items)
        popup.identifier = NSUserInterfaceItemIdentifier(key)
        popup.target = target
        popup.action = action

        // Select saved value if exists
        if let savedValue = UserDefaults.standard.string(forKey: key),
           let index = items.firstIndex(of: savedValue) {
            popup.selectItem(at: index)
        }

        stackView.addArrangedSubview(labelField)
        stackView.addArrangedSubview(popup)

        container.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            labelField.widthAnchor.constraint(equalToConstant: 150)
        ])

        return container
    }
}
