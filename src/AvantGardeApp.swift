import SwiftUI

@main
struct AvantGardeApp: App {

    @StateObject private var viewModel = DocumentViewModel()
    @StateObject private var themeManager = ColorThemeManager.shared
    @StateObject private var updateChecker = UpdateChecker.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
                .onAppear {
                    // Check for updates after 3 seconds on launch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        updateChecker.checkForUpdates(isAutoCheck: true)
                    }
                }
        }
        .commands {
            // App menu
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updateChecker.checkForUpdates()
                }
            }

            // File menu additions
            CommandGroup(after: .newItem) {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As...") {
                    Task { await viewModel.saveAs() }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Divider()

                Button("Export for KDP...") {
                    Task { await viewModel.exportKDP() }
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])

                Button("Export for Google Play...") {
                    Task { await viewModel.exportGoogle() }
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
            }

            // View menu additions
            CommandGroup(after: .sidebar) {
                Button("Themes") {
                    viewModel.isShowingThemePicker = true
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])

                Button("Book Settings") {
                    viewModel.isShowingSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            // Audio menu
            CommandMenu("Audio") {
                Button("Play / Pause") {
                    if viewModel.ttsIsPlaying && !viewModel.ttsIsPaused {
                        viewModel.pauseTTS()
                    } else if viewModel.ttsIsPaused {
                        viewModel.resumeTTS()
                    } else {
                        viewModel.playTTS()
                    }
                }
                .keyboardShortcut(" ", modifiers: .command)

                Button("Stop") {
                    viewModel.stopTTS()
                }
                .keyboardShortcut(".", modifiers: .command)

                Divider()

                Button("Voice Settings") {
                    viewModel.isShowingTTSPlayer = true
                }
            }
        }
    }
}
