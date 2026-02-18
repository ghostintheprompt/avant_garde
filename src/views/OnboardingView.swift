import SwiftUI

struct OnboardingView: View {

    @Binding var isPresented: Bool
    @State private var page = 0

    private let pages: [OnboardingPage] = [
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
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: advance) {
                Text(page < pages.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .padding(.top, 8)
        }
        .background(Color(.systemBackground))
        .interactiveDismissDisabled()
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation { page += 1 }
        } else {
            isPresented = false
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
                    .padding(.horizontal, 16)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isPresented: .constant(true))
}
