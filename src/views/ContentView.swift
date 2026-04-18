import SwiftUI

struct ContentView: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    @EnvironmentObject var themeManager: ColorThemeManager

    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var isShowingOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var writeError: String?

    private var colors: ColorThemeManager.ThemeColors {
        themeManager.currentTheme.colors
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ChapterListView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 350)
                .background(colors.sidebar)
        } detail: {
            ChapterEditorView()
                .background(colors.background)
        }
        .navigationTitle(viewModel.document.metadata.title.isEmpty ? "Avant Garde" : viewModel.document.metadata.title)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    viewModel.isShowingSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .help("Book Settings")

                Button {
                    viewModel.isShowingThemePicker = true
                } label: {
                    Image(systemName: "paintbrush")
                }
                .help("Change Theme")
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.showValidationSheet = true
                } label: {
                    Image(systemName: "checkmark.seal")
                }
                .help("Validate Manuscript")

                Button {
                    Task { await viewModel.exportKDP() }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .help("Export for KDP")
            }
        }
        // Custom Branding Overlays
        .sheet(isPresented: $viewModel.isShowingThemePicker) {
            ThemePickerView()
                .frame(width: 600, height: 500)
        }
        .sheet(isPresented: $viewModel.isShowingSettings) {
            BookSettingsView(initialMetadata: viewModel.document.metadata)
                .frame(width: 500, height: 600)
        }
        .sheet(isPresented: $viewModel.isShowingTTSPlayer) {
            TTSPlayerView()
                .frame(width: 400, height: 500)
        }
        .sheet(isPresented: $isShowingOnboarding) {
            OnboardingView(isPresented: $isShowingOnboarding)
                .onDisappear {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }
        }
        .sheet(isPresented: $viewModel.showExportSheet) {
            if let exported = viewModel.exportedData {
                ExportShareView(exportedFile: exported)
                    .frame(width: 400, height: 300)
            }
        }
        .alert("Export Error", isPresented: Binding(
            get: { viewModel.exportError != nil },
            set: { if !$0 { viewModel.exportError = nil } }
        )) {
            Button("OK") { viewModel.exportError = nil }
        } message: {
            Text(viewModel.exportError ?? "An unknown error occurred during export.")
        }
    }
}

// MARK: - Export Share View

private struct ExportShareView: View {
    let exportedFile: ExportedFile
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.arrow.up")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            
            VStack(spacing: 8) {
                Text("Ready to Ship")
                    .font(.headline)
                Text("Your manuscript has been professionally formatted and is ready for distribution.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Save \(exportedFile.suggestedFileName)...") {
                saveFile()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("Done") { dismiss() }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }

    private func saveFile() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [exportedFile.contentType == "text/html" ? .html : .epub]
        savePanel.nameFieldStringValue = exportedFile.suggestedFileName
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                try? exportedFile.data.write(to: url)
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(DocumentViewModel())
        .environmentObject(ColorThemeManager.shared)
}
