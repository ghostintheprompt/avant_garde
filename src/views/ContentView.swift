import SwiftUI

struct ContentView: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    @EnvironmentObject var themeManager: ColorThemeManager

    @Environment(\.horizontalSizeClass) private var sizeClass

    // iPhone: sheet-based import
    @State private var showDocumentPicker = false
    // iPad: sidebar starts visible; iPhone: collapses to stack
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ChapterListView()
        } detail: {
            ChapterEditorView()
        }
        .navigationSplitViewStyle(.balanced)
        // Status bar at bottom of detail
        .safeAreaInset(edge: .bottom) {
            StatusBar()
        }
        // Themed background
        .background(themeManager.currentTheme.colors.background)
        // ---- Sheets ----
        .sheet(isPresented: $viewModel.isShowingSettings) {
            BookSettingsView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.isShowingThemePicker) {
            ThemePickerView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $viewModel.isShowingTTSPlayer) {
            TTSPlayerView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showValidationSheet) {
            if let report = viewModel.validationReport {
                ValidationResultsView(report: report)
            }
        }
        .sheet(isPresented: $viewModel.showExportSheet) {
            if let exported = viewModel.exportedData {
                ExportShareView(file: exported)
            }
        }
        // ---- Alerts ----
        .alert("Export Error", isPresented: .constant(viewModel.exportError != nil)) {
            Button("OK") { viewModel.exportError = nil }
        } message: {
            Text(viewModel.exportError ?? "")
        }
        // ---- Document import ----
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                viewModel.load(from: url)
            }
        }
        .toolbar {
            // Leading: document actions
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Menu {
                    Button("New Book", systemImage: "doc.badge.plus") {
                        viewModel.newDocument()
                    }
                    Button("Open...", systemImage: "folder") {
                        showDocumentPicker = true
                    }
                    Divider()
                    Button("Book Settings", systemImage: "gear") {
                        viewModel.isShowingSettings = true
                    }
                } label: {
                    Image(systemName: "doc.text")
                }
            }

            // Trailing: export + theme + TTS
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    viewModel.isShowingThemePicker = true
                } label: {
                    Image(systemName: "paintpalette")
                }
                .help("Change Theme")

                Menu {
                    Button("Validate for KDP", systemImage: "checkmark.seal") {
                        viewModel.validateKDP()
                    }
                    Button("Validate for Google Play", systemImage: "checkmark.seal") {
                        viewModel.validateGoogle()
                    }
                    Divider()
                    Button("Export for KDP", systemImage: "arrow.up.doc") {
                        Task { await viewModel.exportKDP() }
                    }
                    Button("Export for Google Play", systemImage: "arrow.up.doc.fill") {
                        Task { await viewModel.exportGoogle() }
                    }
                } label: {
                    if viewModel.isExporting {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .help("Export")

                Button {
                    viewModel.isShowingTTSPlayer = true
                } label: {
                    Image(systemName: viewModel.ttsIsPlaying ? "waveform" : "headphones")
                }
                .help("Listen")
                .symbolEffect(.variableColor, isActive: viewModel.ttsIsPlaying)
            }
        }
    }
}

// MARK: - Status Bar

private struct StatusBar: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    @EnvironmentObject var themeManager: ColorThemeManager

    var body: some View {
        HStack(spacing: 16) {
            Label("\(viewModel.wordCount) words", systemImage: "text.word.spacing")
            Label("\(viewModel.estimatedReadingMinutes) min read", systemImage: "clock")

            Spacer()

            if viewModel.hasUnsavedChanges {
                Label("Unsaved", systemImage: "pencil.circle")
                    .foregroundStyle(.orange)
            } else {
                Label("Saved", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Export Share View

struct ExportShareView: View {

    @Environment(\.dismiss) var dismiss
    let file: ExportedFile

    @State private var tempURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                if let url = tempURL {
                    VStack(spacing: 24) {
                        Image(systemName: "doc.badge.checkmark")
                            .font(.system(size: 56))
                            .foregroundStyle(.green)

                        Text(file.suggestedFileName)
                            .font(.headline)

                        ShareLink(
                            item: url,
                            subject: Text(file.suggestedFileName),
                            message: Text("Exported from Avant Garde"),
                            preview: SharePreview(file.suggestedFileName, image: Image(systemName: "doc.text"))
                        ) {
                            Label("Share File", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: 280)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView("Preparing export...")
                        .onAppear { writeTempFile() }
                }
            }
            .navigationTitle("Export Ready")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func writeTempFile() {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(file.suggestedFileName)
        do {
            try file.data.write(to: tmp, options: .atomic)
            tempURL = tmp
        } catch {
            Logger.error("Failed to write temp export file", error: error, category: .general)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(DocumentViewModel())
        .environmentObject(ColorThemeManager.shared)
}
