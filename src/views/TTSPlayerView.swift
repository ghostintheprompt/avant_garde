import SwiftUI

struct TTSPlayerView: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) var dismiss

    @State private var speechRate: Float = 0.5
    @State private var speechVolume: Float = 1.0
    @State private var selectedVoice: VoiceOption?

    private var tts: TextToSpeech { ServiceContainer.shared.textToSpeech }

    var body: some View {
        NavigationStack {
            List {
                Section { PlayerControlsRow() }
                nowPlayingSection
                speedSection
                volumeSection
                voiceSection
            }
            .navigationTitle("Listen")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                speechRate = tts.currentRate
                speechVolume = tts.currentVolume
                selectedVoice = tts.getCurrentVoice()
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var nowPlayingSection: some View {
        if let title = nowPlayingTitle {
            Section("Now Playing") {
                Label(title, systemImage: "waveform")
                    .foregroundStyle(.primary)
            }
        }
    }

    private var speedSection: some View {
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
    }

    private var volumeSection: some View {
        Section("Volume") {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Volume")
                    Spacer()
                    Text("\(Int(speechVolume * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $speechVolume, in: 0.0...1.0, step: 0.05)
                    .onChange(of: speechVolume) { volume in
                        viewModel.setTTSVolume(volume)
                    }
            }
        }
    }

    private var voiceSection: some View {
        Section("Voice") {
            let voices = viewModel.availableVoices.filter { $0.language.hasPrefix("en") }
            if voices.isEmpty {
                Text("No English voices available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(voices, id: \.id) { voice in
                    VoiceRow(
                        voice: voice,
                        isSelected: selectedVoice?.id == voice.id
                    ) {
                        selectedVoice = voice
                        viewModel.setTTSVoice(voice)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var nowPlayingTitle: String? {
        guard viewModel.ttsIsPlaying || viewModel.ttsIsPaused else { return nil }
        let index = viewModel.ttsCurrentChapterIndex
        guard index < viewModel.document.chapters.count else { return nil }
        return viewModel.document.chapters[index].title
    }

    private func speedLabel(_ rate: Float) -> String {
        String(format: "%.2fx", rate / 0.5)
    }
}

// MARK: - Voice Row

private struct VoiceRow: View {
    let voice: VoiceOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(voice.displayName)
                        .foregroundStyle(.primary)
                    Text(voice.language)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

// MARK: - Player Controls Row

private struct PlayerControlsRow: View {

    @EnvironmentObject var viewModel: DocumentViewModel

    var body: some View {
        HStack(spacing: 32) {
            Spacer()

            Button {
                let prev = viewModel.ttsCurrentChapterIndex - 1
                if prev >= 0 {
                    viewModel.select(chapterAt: prev)
                    viewModel.stopTTS()
                    viewModel.playTTS()
                }
            } label: {
                Image(systemName: "backward.fill").font(.title2)
            }
            .disabled(!viewModel.ttsIsPlaying)

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

            Button {
                let next = viewModel.ttsCurrentChapterIndex + 1
                if next < viewModel.document.chapters.count {
                    viewModel.select(chapterAt: next)
                    viewModel.stopTTS()
                    viewModel.playTTS()
                }
            } label: {
                Image(systemName: "forward.fill").font(.title2)
            }
            .disabled(!viewModel.ttsIsPlaying)

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var playPauseIcon: String {
        viewModel.ttsIsPlaying && !viewModel.ttsIsPaused ? "pause.fill" : "play.fill"
    }
}

// MARK: - Preview

#Preview {
    TTSPlayerView()
        .environmentObject(DocumentViewModel())
}
