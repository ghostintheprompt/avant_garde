import SwiftUI

struct ChapterListView: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    @EnvironmentObject var themeManager: ColorThemeManager

    var body: some View {
        List(selection: $viewModel.selectedChapterID) {
            ForEach(viewModel.document.chapters) { chapter in
                ChapterRow(chapter: chapter)
                    .tag(chapter.id)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            viewModel.duplicateChapter(id: chapter.id)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteChapter(id: chapter.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onMove { source, destination in
                viewModel.moveChapters(from: source, to: destination)
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.addChapter()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Chapter")
            }
        }
        .navigationTitle(
            viewModel.document.metadata.title.isEmpty
                ? "Untitled Book"
                : viewModel.document.metadata.title
        )
    }
}

// MARK: - Chapter Row

private struct ChapterRow: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    let chapter: Chapter

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chapter.title.isEmpty ? "Untitled Chapter" : chapter.title)
                .font(.body)
                .lineLimit(1)

            Text(wordCountLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    private var wordCountLabel: String {
        let count = chapter.content
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
        return "\(count) word\(count == 1 ? "" : "s")"
    }
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        ChapterListView()
    } detail: {
        Text("Select a chapter")
    }
    .environmentObject(DocumentViewModel())
    .environmentObject(ColorThemeManager.shared)
}
