import Foundation
import SwiftUI

/// Professional Book Layout & Typography Engine
/// Implements high-end book design techniques like Vellum/KDP but better.
class FormattingEngine {

    static let shared = FormattingEngine()

    // MARK: - Style Matrix

    struct StyleDefinition {
        let headingFont: String
        let bodyFont: String
        let lineSpacing: Double
        let mood: String
    }

    private let styleMatrix: [StylePreset: StyleDefinition] = [
        .meridian: StyleDefinition(headingFont: "Playfair Display, serif", bodyFont: "EB Garamond, serif", lineSpacing: 1.45, mood: "Professional, Versatile"),
        .serein: StyleDefinition(headingFont: "Cormorant Garamond, serif", bodyFont: "Lora, serif", lineSpacing: 1.6, mood: "Airy, Romantic, Minimal"),
        .oxford: StyleDefinition(headingFont: "Inter, sans-serif", bodyFont: "Libre Baskerville, serif", lineSpacing: 1.5, mood: "Academic, Non-Fiction"),
        .vogue: StyleDefinition(headingFont: "Montserrat, sans-serif", bodyFont: "Open Sans, sans-serif", lineSpacing: 1.4, mood: "Tech, Modern, High-Fashion"),
        .legible: StyleDefinition(headingFont: "Atkinson Hyperlegible, sans-serif", bodyFont: "Atkinson Hyperlegible, sans-serif", lineSpacing: 1.5, mood: "Maximum Readability")
    ]

    // MARK: - CSS Generation

    func generateCSS(for metadata: BookMetadata) -> String {
        let preset = metadata.preset
        let style = styleMatrix[preset] ?? styleMatrix[.meridian]!
        let hyphenation = metadata.enableHyphenation ? "auto" : "none"
        
        return """
        body {
            font-family: \(style.bodyFont);
            font-size: 12pt;
            line-height: \(style.lineSpacing);
            text-align: justify;
            hyphens: \(hyphenation);
            -webkit-hyphens: \(hyphenation);
            margin: 0;
            padding: 0;
        }

        @page {
            margin: 1in;
        }

        /* Chapter Headers (The Sink) */
        .chapter-container {
            page-break-before: always;
            padding-top: 25vh; /* The Sink: 25% of container height */
            text-align: center;
            margin-bottom: 4rem;
        }

        .chapter-label {
            font-family: \(style.headingFont);
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 2px;
            color: #666;
            margin-bottom: 0.5rem;
        }

        .chapter-title {
            font-family: \(style.headingFont);
            font-size: 2.5rem;
            font-weight: bold;
            margin-bottom: 2rem;
        }

        .fleuron {
            font-size: 1.5rem;
            padding: 2rem 0;
            color: #333;
        }

        /* Paragraphs */
        p {
            margin: 0;
            text-indent: 1.5em;
        }

        /* The First Paragraph Anchor */
        .first-paragraph {
            text-indent: 0 !important;
            margin-top: 2rem;
        }

        .drop-cap {
            float: left;
            font-family: \(style.headingFont);
            font-size: 4.2rem;
            line-height: 0.8;
            padding-top: 4px;
            padding-right: 8px;
            padding-left: 3px;
        }

        .small-caps {
            font-variant: small-caps;
            letter-spacing: 1px;
        }

        /* Scene Breaks */
        .scene-break {
            text-align: center;
            padding: 2rem 0;
        }

        /* Specialty Modules */
        .chat-bubble {
            max-width: 70%;
            padding: 10px 15px;
            border-radius: 15px;
            margin: 5px 0;
            font-family: sans-serif;
            font-size: 0.9rem;
            text-indent: 0;
        }

        .chat-left {
            align-self: flex-start;
            background-color: #e9e9eb;
            color: black;
            margin-right: auto;
        }

        .chat-right {
            align-self: flex-end;
            background-color: #007aff;
            color: white;
            margin-left: auto;
        }

        .letter {
            margin: 2rem 10%;
            font-family: 'Courier New', Courier, monospace;
            border-left: 3px solid #eee;
            padding-left: 1.5rem;
            text-indent: 0;
        }
        """
    }

    // MARK: - HTML Processing

    func formatChapter(_ chapter: Chapter, metadata: BookMetadata, index: Int) -> String {
        let preset = metadata.preset
        var html = "<div class=\"chapter-container\">\n"
        html += "    <div class=\"chapter-label\">Chapter \(numberToWords(index + 1))</div>\n"
        html += "    <div class=\"chapter-title\">\(chapter.title.htmlEscaped)</div>\n"
        html += "    <div class=\"fleuron\">&#10086;</div>\n"
        html += "</div>\n"

        let paragraphs = chapter.content.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for (pIndex, pText) in paragraphs.enumerated() {
            if pIndex == 0 {
                html += formatFirstParagraph(pText, metadata: metadata)
            } else if pText == "***" || pText == "* * *" {
                html += "    <div class=\"scene-break\">&#10086;</div>\n"
            } else if pText.starts(with: "[LETTER]") {
                html += "    <div class=\"letter\">\(pText.replacingOccurrences(of: "[LETTER]", with: "").htmlEscaped)</div>\n"
            } else if pText.starts(with: "A:") {
                html += "    <div class=\"chat-bubble chat-left\">\(pText.replacingOccurrences(of: "A:", with: "").htmlEscaped)</div>\n"
            } else if pText.starts(with: "B:") {
                html += "    <div class=\"chat-bubble chat-right\">\(pText.replacingOccurrences(of: "B:", with: "").htmlEscaped)</div>\n"
            } else {
                html += "    <p>\(pText.htmlEscaped)</p>\n"
            }
        }

        return html
    }

    private func formatFirstParagraph(_ text: String, metadata: BookMetadata) -> String {
        let words = text.components(separatedBy: .whitespaces)
        guard !words.isEmpty else { return "<p class=\"first-paragraph\">\(text.htmlEscaped)</p>" }

        if !metadata.enableDropCaps {
            return "<p class=\"first-paragraph\">\(text.htmlEscaped)</p>"
        }

        let firstWord = words[0]
        let remainingText = words.dropFirst().joined(separator: " ")
        
        let firstLetter = String(firstWord.prefix(1))
        let restOfFirstWord = String(firstWord.dropFirst())
        
        // Simple Drop Cap implementation
        return """
            <p class="first-paragraph">
                <span class="drop-cap">\(firstLetter)</span>
                <span class="small-caps">\(restOfFirstWord)</span> \(remainingText.htmlEscaped)
            </p>
        """
    }

    private func numberToWords(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter.string(from: NSNumber(value: number))?.capitalized ?? "\(number)"
    }

    // MARK: - Live Preview Support

    #if os(macOS)
    func getLiveFont(for preset: StylePreset, size: CGFloat = 14) -> Font {
        switch preset {
        case .meridian:
            return .custom("Playfair Display", size: size).italic()
        case .serein:
            return .custom("Cormorant Garamond", size: size)
        case .oxford:
            return .system(size: size, weight: .medium, design: .serif)
        case .vogue:
            return .system(size: size, weight: .light, design: .default)
        case .legible:
            return .system(size: size, weight: .regular, design: .monospaced)
        }
    }

    func getLiveBodyFont(for preset: StylePreset, size: CGFloat = 14) -> Font {
        switch preset {
        case .meridian, .serein, .oxford:
            return .system(size: size, weight: .regular, design: .serif)
        case .vogue:
            return .system(size: size, weight: .regular, design: .default)
        case .legible:
            return .system(size: size, weight: .regular, design: .monospaced)
        }
    }
    #endif
}
