import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

struct OnboardingView: View {

    @Binding var isPresented: Bool
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "paintbrush.fill",
            title: "Choose Your Atmosphere",
            body: "Select a writing theme based on your genre and focus needs. Each theme uses research-backed color psychology to optimize your performance."
        ),
        OnboardingPage(
            systemImage: "doc.richtext",
            title: "Write Your Book",
            body: "Organize your chapters in the sidebar and write freely in the editor. Avant Garde auto-saves as you go."
        ),
        OnboardingPage(
            systemImage: "waveform",
            title: "Listen as You Work",
            body: "Tap the headphones icon to have any chapter read aloud. Adjust speed and voice to suit your style."
        ),
        OnboardingPage(
            systemImage: "arrow.up.doc",
            title: "Export Anywhere",
            body: "Validate and export your manuscript for Amazon KDP or Google Play Books with a single tap."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(pages.indices, id: \.self) { index in
                    if page == index {
                        VStack {
                            OnboardingPageView(page: pages[index])
                            
                            if index == 0 {
                                ThemeSelectionGrid()
                                    .padding(.top, -20)
                                    .padding(.bottom, 20)
                            }
                        }
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Page Indicator
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Circle()
                        .fill(page == index ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 24)

            Button(action: advance) {
                Text(page < pages.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(width: 500, height: 500)
        .background(windowBackgroundColor)
    }

    private var windowBackgroundColor: Color {
        #if canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation(.spring()) { page += 1 }
        } else {
            isPresented = false
        }
    }
}

// MARK: - Theme Selection Grid

private struct ThemeSelectionGrid: View {
    @EnvironmentObject var themeManager: ColorThemeManager

    let themes: [ColorThemeManager.WritingTheme] = [.gonzo, .focused, .creative, .calm]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(themes) { theme in
                Button {
                    themeManager.applyTheme(theme)
                } label: {
                    VStack {
                        Circle()
                            .fill(theme.colors.background)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(themeManager.currentTheme == theme ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 2)
                            )
                            .shadow(radius: 2)
                        Text(theme.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Page Model

private struct OnboardingPage {
    let systemImage: String
    let title: String
    let body: String
}

// MARK: - Page View

private struct OnboardingPageView: View {

    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: page.systemImage)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.tint)
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environmentObject(ColorThemeManager.shared)
}
