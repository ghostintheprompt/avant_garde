import SwiftUI

struct ChapterListView: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    @EnvironmentObject var themeManager: ColorThemeManager

    private var colors: ColorThemeManager.ThemeColors {
        themeManager.currentTheme.colors
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header / Brand Area
            HStack {
                Text("MANUSCRIPT")
                    .font(.system(size: 10, weight: .black))
                    .kerning(2)
                    .foregroundStyle(colors.text.opacity(0.5))
                Spacer()
                Button {
                    viewModel.addChapter()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(colors.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colors.sidebar)

            List(selection: $viewModel.selectedChapterID) {
                ForEach(viewModel.document.chapters) { chapter in
                    ChapterRow(chapter: chapter, isSelected: viewModel.selectedChapterID == chapter.id)
                        .tag(chapter.id)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .onMove(perform: viewModel.moveChapters)
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteChapter(id: viewModel.document.chapters[index].id)
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(colors.sidebar)
        }
        .background(colors.sidebar)
    }
}

// MARK: - Chapter Row

private struct ChapterRow: View {
    @EnvironmentObject var themeManager: ColorThemeManager
    let chapter: Chapter
    let isSelected: Bool

    private var colors: ColorThemeManager.ThemeColors {
        themeManager.currentTheme.colors
    }

    var body: some View {
        HStack(spacing: 12) {
            // Tactical Indicator
            Rectangle()
                .fill(isSelected ? colors.accent : Color.clear)
                .frame(width: 3)
                .cornerRadius(1.5)

            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.title.isEmpty ? "Untitled Chapter" : chapter.title)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? colors.text : colors.text.opacity(0.7))
                    .lineLimit(1)
                
                HStack {
                    Text("\(chapter.cachedWordCount) words")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(colors.text.opacity(0.4))
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? colors.accent.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        ChapterListView()
            .environmentObject(DocumentViewModel())
            .environmentObject(ColorThemeManager.shared)
    } detail: {
        Text("Preview")
    }
}
