import Foundation
import AVFoundation

protocol AudioControllerDelegate: AnyObject {
    func audioDidStart()
    func audioDidFinish()
    func audioDidPause()
    func audioPlaybackProgress(_ progress: Float)
    func audioError(_ error: Error)
}

class AudioController: NSObject {
    private var audioPlayer: AVAudioPlayer?
    private let textToSpeech = TextToSpeech()
    private var playbackTimer: Timer?
    
    weak var delegate: AudioControllerDelegate?
    
    // Current playback state
    private(set) var isPlayingAudio = false
    private(set) var isReadingText = false
    private(set) var currentDocument: EbookDocument?
    private(set) var currentChapterIndex = 0
    
    override init() {
        super.init()
        textToSpeech.delegate = self
    }

    deinit {
        stopPlaybackTimer()
        audioPlayer?.stop()
        textToSpeech.stopSpeaking()
    }

    // MARK: - Audio File Playback
    
    func playAudio(from url: URL) {
        Logger.info("Starting audio playback from: \(url.lastPathComponent)", category: .audio)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            isPlayingAudio = true
            startPlaybackTimer()
            delegate?.audioDidStart()
            Logger.debug("Audio playback started successfully", category: .audio)
        } catch {
            Logger.error("Audio playback failed", error: error, category: .audio)
            delegate?.audioError(error)
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        stopPlaybackTimer()
        isPlayingAudio = false
        delegate?.audioDidFinish()
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        stopPlaybackTimer()
        delegate?.audioDidPause()
    }
    
    func resumeAudio() {
        audioPlayer?.play()
        startPlaybackTimer()
        delegate?.audioDidStart()
    }
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updatePlaybackProgress()
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updatePlaybackProgress() {
        guard let player = audioPlayer else { return }
        
        let progress = Float(player.currentTime / player.duration)
        delegate?.audioPlaybackProgress(progress)
    }
    
    // MARK: - Text-to-Speech
    
    func readTextAloud(_ text: String) {
        Logger.info("Starting text-to-speech for \(text.count) characters", category: .audio)
        textToSpeech.speak(text: text)
        isReadingText = true
    }

    func readChapter(_ chapter: Chapter) {
        Logger.info("Reading chapter: \(chapter.title)", category: .audio)
        textToSpeech.speakChapter(chapter)
        isReadingText = true
    }

    func readDocument(_ document: EbookDocument, startingFromChapter: Int = 0) {
        Logger.info("Starting document reading: \(document.metadata.title) from chapter \(startingFromChapter + 1)", category: .audio)
        currentDocument = document
        currentChapterIndex = startingFromChapter

        guard currentChapterIndex < document.chapters.count else {
            Logger.warning("Invalid chapter index: \(currentChapterIndex) for document with \(document.chapters.count) chapters", category: .audio)
            return
        }

        let chapter = document.chapters[currentChapterIndex]
        readChapter(chapter)
    }
    
    func readNextChapter() {
        guard let document = currentDocument else { return }
        
        currentChapterIndex += 1
        
        if currentChapterIndex < document.chapters.count {
            let chapter = document.chapters[currentChapterIndex]
            readChapter(chapter)
        } else {
            // Finished reading the entire document
            stopTextToSpeech()
        }
    }
    
    func readPreviousChapter() {
        guard let document = currentDocument else { return }
        
        currentChapterIndex = max(0, currentChapterIndex - 1)
        let chapter = document.chapters[currentChapterIndex]
        readChapter(chapter)
    }
    
    func stopTextToSpeech() {
        textToSpeech.stopSpeaking()
        isReadingText = false
        currentDocument = nil
        currentChapterIndex = 0
    }
    
    func pauseTextToSpeech() {
        textToSpeech.pauseSpeaking()
    }
    
    func resumeTextToSpeech() {
        textToSpeech.continueSpeaking()
    }
    
    // MARK: - Voice Management
    
    func getAvailableVoices() -> [VoiceOption] {
        return textToSpeech.availableVoices
    }
    
    func getRecommendedVoices() -> [VoiceOption] {
        return textToSpeech.getRecommendedVoices()
    }
    
    func setVoice(_ voice: VoiceOption) {
        textToSpeech.setVoice(voice)
    }
    
    func setSpeechRate(_ rate: Float) {
        textToSpeech.setSpeechRate(rate)
    }
    
    func setSpeechPitch(_ pitch: Float) {
        textToSpeech.setSpeechPitch(pitch)
    }
    
    func setSpeechVolume(_ volume: Float) {
        textToSpeech.setSpeechVolume(volume)
    }
    
    // MARK: - Playback State
    
    var isSpeaking: Bool {
        return textToSpeech.isSpeaking
    }
    
    var isPaused: Bool {
        return textToSpeech.isPaused
    }
    
    var isPlaying: Bool {
        return isPlayingAudio || isReadingText
    }
    
    func getCurrentChapterTitle() -> String? {
        guard let document = currentDocument,
              currentChapterIndex < document.chapters.count else { return nil }
        
        return document.chapters[currentChapterIndex].title
    }
    
    func getPlaybackInfo() -> (currentChapter: Int, totalChapters: Int, chapterTitle: String)? {
        guard let document = currentDocument else { return nil }
        
        return (
            currentChapter: currentChapterIndex + 1,
            totalChapters: document.chapters.count,
            chapterTitle: getCurrentChapterTitle() ?? "Unknown Chapter"
        )
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlaybackTimer()
        isPlayingAudio = false
        delegate?.audioDidFinish()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            delegate?.audioError(error)
        }
    }
}

// MARK: - TextToSpeechDelegate

extension AudioController: TextToSpeechDelegate {
    func speechDidStart() {
        delegate?.audioDidStart()
    }
    
    func speechDidFinish() {
        isReadingText = false
        
        // If we're reading a document, automatically move to the next chapter
        if currentDocument != nil {
            readNextChapter()
        } else {
            delegate?.audioDidFinish()
        }
    }
    
    func speechDidPause() {
        delegate?.audioDidPause()
    }
    
    func speechDidContinue() {
        delegate?.audioDidStart()
    }
    
    func speechProgress(range: NSRange, utterance: AVSpeechUtterance) {
        // Calculate approximate progress through the current utterance
        let progress = Float(range.location) / Float(utterance.speechString.count)
        delegate?.audioPlaybackProgress(progress)
    }
}