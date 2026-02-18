import SwiftUI

struct ContentView: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    @EnvironmentObject var themeManager: ColorThemeManager

    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var showLibrary = false
    @AppStorage("onboardingComplete") private var onboardingComplete = false
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
        .sheet(isPresented: $showLibrary) {
            DocumentLibraryView()
                .environmentObject(viewModel)
        }
        .fullScreenCover(isPresented: .init(
            get: { !onboardingComplete },
            set: { if !$0 { onboardingComplete = true } }
        )) {
            OnboardingView(isPresented: .init(
                get: { !onboardingComplete },
                set: { if !$0 { onboardingComplete = true } }
            ))
        }
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
                ValidationResultsView(report: report) {
                    viewModel.isShowingSettings = true
                }
            }
        }
        .sheet(isPresented: $viewModel.showExportSheet) {
            if let exported = viewModel.exportedData {
                ExportShareView(file: exported)
            }
        }
        // ---- Alerts ----
        .alert("Validation Issues", isPresented: $viewModel.showExportValidationAlert) {
            Button("Export Anyway", role: .destructive) {
                Task { await viewModel.confirmExportDespiteErrors() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let errors = viewModel.exportValidationErrors
            Text(errors.count == 1
                ? errors[0]
                : "\(errors.count) errors must be fixed:\n" + errors.prefix(3).joined(separator: "\n"))
        }
        .alert("Export Error", isPresented: .constant(viewModel.exportError != nil)) {
            Button("OK") { viewModel.exportError = nil }
        } message: {
            Text(viewModel.exportError ?? "")
        }
        .toolbar {
            // Leading: document actions
            ToolbarItemGroup(placement: .topBarLeading) {
                Menu {
                    Button("New Book", systemImage: "doc.badge.plus") {
                        viewModel.newDocument()
                    }
                    Button("Open...", systemImage: "folder") {
                        showLibrary = true
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
            ToolbarItemGroup(placement: .topBarTrailing) {
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
                .disabled(viewModel.isExporting)

                Button {
                    viewModel.isShowingTTSPlayer = true
                } label: {
                    Image(systemName: viewModel.ttsIsPlaying ? "waveform" : "headphones")
                        .foregroundStyle(viewModel.ttsIsPlaying ? Color.accentColor : Color.primary)
                }
                .help("Listen")
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
