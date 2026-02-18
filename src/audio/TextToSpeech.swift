import Foundation
import AVFoundation

struct VoiceOption: Identifiable {
    var id: String { voice.identifier }
    let voice: AVSpeechSynthesisVoice
    let displayName: String
    let language: String
    let quality: AVSpeechSynthesisVoiceQuality

    init(voice: AVSpeechSynthesisVoice) {
        self.voice = voice
        self.displayName = voice.name
        self.language = voice.language
        self.quality = voice.quality
    }
}

protocol TextToSpeechDelegate: AnyObject {
    func speechDidStart()
    func speechDidFinish()
    func speechDidPause()
    func speechDidContinue()
    func speechProgress(range: NSRange, utterance: AVSpeechUtterance)
}

class TextToSpeech: NSObject {
    private var synthesizer: AVSpeechSynthesizer
    private var currentVoice: AVSpeechSynthesisVoice?
    private var speechRate: Float = 0.5
    private var speechPitch: Float = 1.0
    private var speechVolume: Float = 1.0

    weak var delegate: TextToSpeechDelegate?

    private(set) var availableVoices: [VoiceOption] = []
    private(set) var englishVoices: [VoiceOption] = []
    private(set) var premiumVoices: [VoiceOption] = []

    override init() {
        synthesizer = AVSpeechSynthesizer()
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
        setupVoices()
        setDefaultVoice()
    }

    // MARK: - Audio Session (iOS only)

    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioSessionInterruption(_:)),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
        } catch {
            Logger.warning("AVAudioSession setup failed: \(error.localizedDescription)", category: .audio)
        }
        #endif
    }

    #if os(iOS)
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        switch type {
        case .began:
            if synthesizer.isSpeaking { synthesizer.pauseSpeaking(at: .word) }
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) { synthesizer.continueSpeaking() }
            }
        @unknown default: break
        }
    }
    #endif

    // MARK: - Voice Setup

    private func setupVoices() {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        availableVoices = allVoices.map { VoiceOption(voice: $0) }
        englishVoices = availableVoices.filter { $0.language.hasPrefix("en") }.sorted { $0.displayName < $1.displayName }
        premiumVoices = availableVoices.filter { $0.quality == .enhanced }.sorted { $0.displayName < $1.displayName }
    }

    private func setDefaultVoice() {
        if let premiumEnglish = premiumVoices.first(where: { $0.language.hasPrefix("en") }) {
            currentVoice = premiumEnglish.voice
        } else if let standardEnglish = englishVoices.first {
            currentVoice = standardEnglish.voice
        } else {
            currentVoice = AVSpeechSynthesisVoice(language: "en-US")
        }
    }

    // MARK: - Voice Selection

    func setVoice(_ voiceOption: VoiceOption) { currentVoice = voiceOption.voice }
    func setVoiceByIdentifier(_ identifier: String) {
        if let voice = AVSpeechSynthesisVoice(identifier: identifier) { currentVoice = voice }
    }
    func getCurrentVoice() -> VoiceOption? {
        guard let voice = currentVoice else { return nil }
        return VoiceOption(voice: voice)
    }

    // MARK: - Speech Control

    func speak(text: String) {
        synthesizer.speak(createUtterance(from: text))
    }

    func speakChapter(_ chapter: Chapter) {
        speak(text: "\(chapter.title). \(chapter.content)")
    }

    func speakDocument(_ document: EbookDocument) {
        let fullText = document.chapters.map { "\($0.title). \($0.content)" }.joined(separator: ". Next chapter. ")
        speak(text: fullText)
    }

    private func createUtterance(from text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = currentVoice
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume
        return utterance
    }

    func pauseSpeaking() { synthesizer.pauseSpeaking(at: .word) }
    func continueSpeaking() { synthesizer.continueSpeaking() }
    func stopSpeaking() { synthesizer.stopSpeaking(at: .immediate) }

    // MARK: - Settings

    func setSpeechRate(_ rate: Float) {
        speechRate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, rate))
    }
    func setSpeechPitch(_ pitch: Float) { speechPitch = max(0.5, min(2.0, pitch)) }
    func setSpeechVolume(_ volume: Float) { speechVolume = max(0.0, min(1.0, volume)) }

    var isSpeaking: Bool { return synthesizer.isSpeaking }
    var isPaused: Bool { return synthesizer.isPaused }
    var currentRate: Float { return speechRate }
    var currentPitch: Float { return speechPitch }
    var currentVolume: Float { return speechVolume }

    // MARK: - Voice Recommendations

    func getRecommendedVoices() -> [VoiceOption] {
        let preferredIDs = [
            "com.apple.ttsbundle.Samantha-compact",
            "com.apple.ttsbundle.Alex-compact",
            "com.apple.ttsbundle.siri_female_en-US_compact",
            "com.apple.ttsbundle.siri_male_en-US_compact"
        ]
        var recommended = preferredIDs.compactMap { id -> VoiceOption? in
            guard let voice = AVSpeechSynthesisVoice(identifier: id) else { return nil }
            return VoiceOption(voice: voice)
        }
        if recommended.isEmpty { return Array(premiumVoices.prefix(4)) }
        return recommended
    }

    func getVoicesByLanguage() -> [String: [VoiceOption]] {
        var result: [String: [VoiceOption]] = [:]
        for voiceOption in availableVoices {
            let code = String(voiceOption.language.prefix(2))
            result[code, default: []].append(voiceOption)
        }
        return result
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeech: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.delegate?.speechDidStart() }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.delegate?.speechDidFinish() }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.delegate?.speechDidPause() }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.delegate?.speechDidContinue() }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.delegate?.speechProgress(range: characterRange, utterance: utterance) }
    }
}
