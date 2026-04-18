import SwiftUI
import Foundation

/// Color psychology-based theming system for enhanced writing experience
class ColorThemeManager: ObservableObject {

    static let shared = ColorThemeManager()

    @Published var currentTheme: WritingTheme = WritingTheme(rawValue: UserDefaults.standard.string(forKey: "selectedTheme") ?? "") ?? .meridian

    // MARK: - Writing Themes

    enum WritingTheme: String, CaseIterable, Identifiable {
        // Light / Matte Professional (Leading)
        case meridian = "Meridian"
        case focused = "Atomic Focus"
        case calm = "Zen Static"
        case creative = "Electric Orange"
        case paper = "Vintage Press"
        
        // Dark / Aggressive (Gonzo & Transmetropolitan)
        case gonzo = "Gonzo Carbon"
        case desert = "Desert Heat"
        case theCity = "The City"
        case ocean = "Midnight Ocean"
        case mystery = "Noir"

        var id: String { rawValue }

        var colors: ThemeColors {
            switch self {
            // LIGHT THEMES
            case .meridian:
                return ThemeColors(
                    background: Color(red: 0.95, green: 0.94, blue: 0.92), // Matte Cream
                    text: Color(red: 0.15, green: 0.18, blue: 0.22),
                    accent: Color(red: 0.72, green: 0.51, blue: 0.25), // Matte Copper
                    sidebar: Color(red: 0.92, green: 0.91, blue: 0.88),
                    editorPaper: Color(red: 0.98, green: 0.97, blue: 0.95)
                )
            case .focused:
                return ThemeColors(
                    background: Color(red: 0.94, green: 0.96, blue: 1.0), // Matte Ice
                    text: Color(red: 0.1, green: 0.2, blue: 0.4),
                    accent: Color(red: 0.2, green: 0.5, blue: 0.9), // Strong Blue
                    sidebar: Color(red: 0.9, green: 0.92, blue: 0.96),
                    editorPaper: .white
                )
            case .calm:
                return ThemeColors(
                    background: Color(white: 0.96),
                    text: Color(white: 0.3),
                    accent: Color(white: 0.5),
                    sidebar: Color(white: 0.92),
                    editorPaper: .white
                )
            case .creative:
                return ThemeColors(
                    background: Color(red: 1.0, green: 0.98, blue: 0.92),
                    text: Color(red: 0.4, green: 0.2, blue: 0.1),
                    accent: Color(red: 1.0, green: 0.45, blue: 0.0), // Strong Matte Orange
                    sidebar: Color(red: 1.0, green: 0.95, blue: 0.88),
                    editorPaper: .white
                )
            case .paper:
                return ThemeColors(
                    background: Color(red: 0.9, green: 0.88, blue: 0.82), // Newsprint
                    text: Color(red: 0.1, green: 0.1, blue: 0.1),
                    accent: Color(red: 0.5, green: 0.3, blue: 0.2),
                    sidebar: Color(red: 0.85, green: 0.83, blue: 0.78),
                    editorPaper: Color(red: 0.94, green: 0.92, blue: 0.86)
                )

            // DARK / AGGRESSIVE THEMES
            case .gonzo:
                return ThemeColors(
                    background: Color(white: 0.08), // Carbon Matte
                    text: Color(white: 0.92),
                    accent: Color(red: 0.9, green: 0.0, blue: 0.1), // Blood Red
                    sidebar: Color(white: 0.04),
                    editorPaper: Color(white: 0.12)
                )
            case .desert:
                return ThemeColors(
                    background: Color(red: 0.15, green: 0.1, blue: 0.05), // Deep Mud
                    text: Color(red: 1.0, green: 0.8, blue: 0.2), // Vegas Yellow
                    accent: Color(red: 1.0, green: 0.4, blue: 0.0), // Sunset Orange
                    sidebar: Color(red: 0.1, green: 0.07, blue: 0.03),
                    editorPaper: Color(red: 0.18, green: 0.12, blue: 0.07)
                )
            case .theCity:
                return ThemeColors(
                    background: Color(red: 0.02, green: 0.02, blue: 0.05), // Absolute Black
                    text: Color(red: 0.0, green: 1.0, blue: 0.4), // Transmet Green
                    accent: Color(red: 1.0, green: 0.0, blue: 0.3), // Glitch Red
                    sidebar: .black,
                    editorPaper: Color(red: 0.05, green: 0.05, blue: 0.08)
                )
            case .ocean:
                return ThemeColors(
                    background: Color(red: 0.02, green: 0.05, blue: 0.15), // Deep Matte Navy
                    text: Color(red: 0.7, green: 0.9, blue: 1.0),
                    accent: Color(red: 0.0, green: 0.9, blue: 1.0), // Cyan
                    sidebar: Color(red: 0.01, green: 0.03, blue: 0.1),
                    editorPaper: Color(red: 0.05, green: 0.08, blue: 0.2)
                )
            case .mystery:
                return ThemeColors(
                    background: Color(white: 0.03),
                    text: Color(white: 0.5),
                    accent: Color(white: 0.2),
                    sidebar: .black,
                    editorPaper: Color(white: 0.06)
                )
            }
        }

        var description: String {
            switch self {
            case .meridian: return "The baseline. Matte cream and slate."
            case .focused: return "Clinical clarity. Ice blue and cobalt."
            case .calm: return "Neutral static. Soft greys for pure drafting."
            case .creative: return "Heat. High-saturation orange for momentum."
            case .paper: return "Old world. Newsprint and heavy ink."
            case .gonzo: return "The Spider Jerusalem. Carbon and blood."
            case .desert: return "Fear and Loathing. Vegas yellow on deep mud."
            case .theCity: return "Information filth. Neon green on absolute black."
            case .ocean: return "Deep thought. Abyssal navy and cyan."
            case .mystery: return "Low visibility. Minimalist noir."
            }
        }
    }

    struct ThemeColors {
        let background: Color
        let text: Color
        let accent: Color
        let sidebar: Color
        let editorPaper: Color

        var selectionColor: Color { accent.opacity(0.2) }
        var placeholderColor: Color { text.opacity(0.3) }
        var dividerColor: Color { text.opacity(0.1) }
    }

    func applyTheme(_ theme: WritingTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
    }

    static func recommendTheme(for genre: String, at date: Date) -> WritingTheme {
        let g = genre.lowercased()
        if g.contains("gonzo") || g.contains("aggressive") { return .gonzo }
        if g.contains("thriller") || g.contains("horror") { return .mystery }
        if g.contains("sci-fi") || g.contains("future") || g.contains("cyber") { return .theCity }
        return .meridian
    }
}
