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
            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    // The Paper
                    VStack(alignment: .leading, spacing: 0) {
                        // Chapter title field
                        TextField("Chapter Title", text: $titleText)
                            .font(FormattingEngine.shared.getLiveFont(for: viewModel.document.metadata.preset, size: 32))
                            .foregroundStyle(colors.text)
                            .textFieldStyle(.plain)
                            .padding(.top, 100) // The Sink
                            .padding(.bottom, 40)
                            .onChange(of: titleText) { newValue in
                                viewModel.updateChapterTitle(newValue, for: chapterID)
                            }

                        // Body editor
                        TextEditor(text: $bodyText)
                            .font(FormattingEngine.shared.getLiveBodyFont(for: viewModel.document.metadata.preset, size: 18))
                            .foregroundStyle(colors.text)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .focused($bodyFocused)
                            .frame(minHeight: 800)
                            .onChange(of: bodyText) { newValue in
                                viewModel.updateChapterContent(newValue, for: chapterID)
                                playTypewriterSound()
                            }
                    }
                    .frame(maxWidth: 720) // Tight reading width for focus
                    .padding(.horizontal, 60)
                    .padding(.bottom, 200)
                    .background(colors.editorPaper)
                    .shadow(color: .black.opacity(themeManager.currentTheme.isDark ? 0.3 : 0.05), radius: 20, x: 0, y: 10)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
            .background(colors.background) // The "Desk" surface

            // Tactical Status Bar
            HStack {
                HStack(spacing: 20) {
                    // Preset Quick Switcher
                    Menu {
                        ForEach(StylePreset.allCases, id: \.self) { preset in
                            Button {
                                viewModel.document.metadata.preset = preset
                                viewModel.objectWillChange.send()
                            } label: {
                                if viewModel.document.metadata.preset == preset {
                                    Label(preset.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(preset.rawValue)
                                }
                            }
                        }
                    } label: {
                        Label(viewModel.document.metadata.preset.rawValue, systemImage: "text.justify.left")
                            .font(.system(size: 10, weight: .black))
                    }
                    .menuStyle(.borderlessButton)
                    
                    Divider().frame(height: 12)
                    
                    Label("\(bodyText.count) chars", systemImage: "text.cursor")
                    Label(wordCountLabel, systemImage: "doc.text")
                }
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(colors.text.opacity(0.5))
                
                Spacer()
                
                HStack(spacing: 16) {
                    if viewModel.hasUnsavedChanges {
                        Text("MODIFIED")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(colors.accent)
                    }
                    
                    Button {
                        viewModel.isShowingPromptVault = true
                    } label: {
                        Label("VAULT", systemImage: "lock.shield")
                            .font(.system(size: 9, weight: .black))
                            .kerning(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(colors.accent.opacity(0.1))
                            .foregroundStyle(colors.accent)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    
                    Text(themeManager.currentTheme.rawValue.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .kerning(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(colors.accent.opacity(0.2))
                        .foregroundStyle(colors.accent)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(colors.sidebar.opacity(0.95))
            .overlay(Divider().foregroundStyle(colors.dividerColor), alignment: .top)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                bodyFocused = true
            }
        }
    }

    // MARK: - Helpers

    private func playTypewriterSound() {
        guard themeManager.currentTheme == .gonzo || themeManager.currentTheme == .theCity else { return }
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
}

extension ColorThemeManager.WritingTheme {
    var isDark: Bool {
        switch self {
        case .gonzo, .theCity, .ocean, .mystery, .desert: return true
        default: return false
        }
    }
}

// MARK: - Empty State

private struct EmptyEditorView: View {
    @EnvironmentObject var viewModel: DocumentViewModel
    @EnvironmentObject var themeManager: ColorThemeManager
    
    private var colors: ColorThemeManager.ThemeColors {
        themeManager.currentTheme.colors
    }

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundStyle(colors.accent.opacity(0.3))

            VStack(spacing: 12) {
                Text("AVANT GARDE")
                    .font(.system(size: 16, weight: .black))
                    .kerning(6)
                    .foregroundStyle(colors.text.opacity(0.8))
                
                Text(viewModel.document.chapters.isEmpty
                     ? "NO CHAPTERS IN MANUSCRIPT"
                     : "SELECT A CHAPTER TO BEGIN")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(colors.text.opacity(0.4))
            }

            if viewModel.document.chapters.isEmpty {
                Button("ADD FIRST CHAPTER") {
                    viewModel.addChapter()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(colors.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}

// MARK: - Preview

#Preview {
    ChapterEditorView()
        .environmentObject(DocumentViewModel())
        .environmentObject(ColorThemeManager.shared)
}
