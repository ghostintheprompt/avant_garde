import SwiftUI

struct TTSPlayerView: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) var dismiss

    @State private var speechRate: Float = 0.5
    @State private var selectedVoice: VoiceOption?

    private var tts: TextToSpeech { ServiceContainer.shared.textToSpeech }

    var body: some View {
        NavigationStack {
            List {
                // MARK: Player Controls
                Section {
                    PlayerControlsRow()
                }

                // MARK: Now Playing
                if let title = nowPlayingTitle {
                    Section("Now Playing") {
                        Label(title, systemImage: "waveform")
                            .foregroundStyle(.primary)
                    }
                }

                // MARK: Speed
                Section("Speed") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Reading Speed")
                            Spacer()
                            Text(speedLabel(speechRate))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $speechRate, in: 0.1...1.0, step: 0.05)
                            .onChange(of: speechRate) { rate in
                                viewModel.setTTSRate(rate)
                            }
                    }
                }

                // MARK: Voice Selection
                Section("Voice") {
                    let voices = viewModel.availableVoices.filter { $0.language.hasPrefix("en") }
                    if voices.isEmpty {
                        Text("No English voices available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(voices, id: \.voice.identifier) { voice in
                            Button {
                                selectedVoice = voice
                                viewModel.setTTSVoice(voice)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(voice.displayName)
                                            .foregroundStyle(.primary)
                                        Text(voice.language)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedVoice?.voice.identifier == voice.voice.identifier {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Listen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                speechRate = tts.currentRate
                selectedVoice = tts.getCurrentVoice()
            }
        }
    }

    private var nowPlayingTitle: String? {
        guard viewModel.ttsIsPlaying || viewModel.ttsIsPaused else { return nil }
        let index = viewModel.ttsCurrentChapterIndex
        guard index < viewModel.document.chapters.count else { return nil }
        return viewModel.document.chapters[index].title
    }

    private func speedLabel(_ rate: Float) -> String {
        String(format: "%.2fx", rate / 0.5) // 0.5 = 1.0x normal
    }
}

// MARK: - Player Controls Row

private struct PlayerControlsRow: View {

    @EnvironmentObject var viewModel: DocumentViewModel

    var body: some View {
        HStack(spacing: 32) {
            Spacer()

            // Previous chapter
            Button {
                let prev = (viewModel.ttsCurrentChapterIndex - 1)
                if prev >= 0 {
                    viewModel.select(chapterAt: prev)
                    viewModel.stopTTS()
                    viewModel.playTTS()
                }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
            }
            .disabled(!viewModel.ttsIsPlaying)

            // Play / Pause / Stop
            Button {
                if viewModel.ttsIsPlaying && !viewModel.ttsIsPaused {
                    viewModel.pauseTTS()
                } else if viewModel.ttsIsPaused {
                    viewModel.resumeTTS()
                } else {
                    viewModel.playTTS()
                }
            } label: {
                Image(systemName: playPauseIcon)
                    .font(.largeTitle)
                    .frame(width: 56, height: 56)
                    .background(.tint, in: Circle())
                    .foregroundStyle(.white)
            }

            // Next chapter
            Button {
                let next = viewModel.ttsCurrentChapterIndex + 1
                if next < viewModel.document.chapters.count {
                    viewModel.select(chapterAt: next)
                    viewModel.stopTTS()
                    viewModel.playTTS()
                }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
            }
            .disabled(!viewModel.ttsIsPlaying)

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var playPauseIcon: String {
        if viewModel.ttsIsPlaying && !viewModel.ttsIsPaused { return "pause.fill" }
        return "play.fill"
    }
}

// MARK: - Preview

#Preview {
    TTSPlayerView()
        .environmentObject(DocumentViewModel())
}
