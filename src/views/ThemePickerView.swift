import SwiftUI

struct ThemePickerView: View {

    @EnvironmentObject var themeManager: ColorThemeManager
    @Environment(\.dismiss) var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ColorThemeManager.WritingTheme.allCases) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: themeManager.currentTheme == theme
                        ) {
                            themeManager.applyTheme(theme)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Writing Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Theme Card

private struct ThemeCard: View {

    let theme: ColorThemeManager.WritingTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Color preview swatch
                HStack(spacing: 4) {
                    theme.colors.background
                        .frame(height: 32)
                        .cornerRadius(6)
                    VStack(spacing: 2) {
                        theme.colors.accent
                            .frame(height: 14)
                            .cornerRadius(3)
                        theme.colors.text
                            .frame(height: 14)
                            .cornerRadius(3)
                    }
                    .frame(width: 28)
                }
                .frame(height: 32)

                Text(theme.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(theme.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 2.5
                    )
            }
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ThemePickerView()
        .environmentObject(ColorThemeManager.shared)
}
