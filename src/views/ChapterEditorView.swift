import SwiftUI

struct ChapterEditorView: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    @EnvironmentObject var themeManager: ColorThemeManager

    var body: some View {
        if let chapter = viewModel.selectedChapter, let id = viewModel.selectedChapterID {
            EditorContent(chapter: chapter, chapterID: id)
                .id(id) // force re-init when chapter selection changes
        } else {
            EmptyEditorView()
        }
    }
}

// MARK: - Editor Content

private struct EditorContent: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    @EnvironmentObject var themeManager: ColorThemeManager

    let chapter: Chapter
    let chapterID: UUID

    @State private var titleText: String
    @State private var bodyText: String
    @FocusState private var bodyFocused: Bool

    init(chapter: Chapter, chapterID: UUID) {
        self.chapter = chapter
        self.chapterID = chapterID
        _titleText = State(initialValue: chapter.title)
        _bodyText = State(initialValue: chapter.content)
    }

    private var colors: ColorThemeManager.ThemeColors {
        themeManager.currentTheme.colors
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chapter title field
            TextField("Chapter Title", text: $titleText)
                .font(.title2.weight(.semibold))
                .foregroundStyle(colors.text)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)
                .onChange(of: titleText) { newValue in
                    viewModel.updateChapterTitle(newValue, for: chapterID)
                }

            Divider()
                .foregroundStyle(colors.dividerColor)

            // Body editor
            TextEditor(text: $bodyText)
                .font(.system(.body, design: .serif))
                .foregroundStyle(colors.text)
                .scrollContentBackground(.hidden)
                .background(colors.background)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .focused($bodyFocused)
                .onChange(of: bodyText) { newValue in
                    viewModel.updateChapterContent(newValue, for: chapterID)
                    playTypewriterSound()
                }
        }
        .background(colors.background)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Word count badge
                Text(wordCountLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())

                // TTS play button for current chapter
                Button {
                    if viewModel.ttsIsPlaying && !viewModel.ttsIsPaused {
                        viewModel.pauseTTS()
                    } else if viewModel.ttsIsPaused {
                        viewModel.resumeTTS()
                    } else {
                        viewModel.playTTS()
                    }
                } label: {
                    Image(systemName: ttsButtonIcon)
                }
                .help(ttsButtonLabel)
            }
        }
        .onAppear {
            // Small delay so keyboard doesn't flash on iPad
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                bodyFocused = true
            }
        }
    }

    // MARK: - Helpers

    private func playTypewriterSound() {
        guard themeManager.currentTheme == .gonzo else { return }
        #if os(macOS)
        NSSound(named: "Tink")?.play()
        #endif
    }

    private var wordCountLabel: String {
        let words = bodyText
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
        return "\(words) words"
    }

    private var ttsButtonIcon: String {
        if viewModel.ttsIsPlaying && !viewModel.ttsIsPaused { return "pause.fill" }
        return "play.fill"
    }

    private var ttsButtonLabel: String {
        if viewModel.ttsIsPlaying && !viewModel.ttsIsPaused { return "Pause reading" }
        if viewModel.ttsIsPaused { return "Resume reading" }
        return "Read chapter aloud"
    }
}

// MARK: - Empty State

private struct EmptyEditorView: View {

    @EnvironmentObject var viewModel: DocumentViewModel

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)

            Text(viewModel.document.chapters.isEmpty
                 ? "No chapters yet"
                 : "Select a chapter to start writing")
                .font(.title3)
                .foregroundStyle(.secondary)

            if viewModel.document.chapters.isEmpty {
                Button("Add First Chapter") {
                    viewModel.addChapter()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ChapterEditorView()
        .environmentObject(DocumentViewModel())
        .environmentObject(ColorThemeManager.shared)
}
