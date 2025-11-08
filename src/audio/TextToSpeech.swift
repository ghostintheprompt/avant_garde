import AVFoundation

struct VoiceOption {
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
    
    // Available voices organized by category
    private(set) var availableVoices: [VoiceOption] = []
    private(set) var englishVoices: [VoiceOption] = []
    private(set) var premiumVoices: [VoiceOption] = []
    
    override init() {
        synthesizer = AVSpeechSynthesizer()
        super.init()
        
        synthesizer.delegate = self
        setupVoices()
        setDefaultVoice()
    }
    
    private func setupVoices() {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        
        availableVoices = allVoices.map { VoiceOption(voice: $0) }
        
        // Filter English voices
        englishVoices = availableVoices.filter { 
            $0.language.hasPrefix("en")
        }.sorted { $0.displayName < $1.displayName }
        
        // Filter premium/enhanced voices
        premiumVoices = availableVoices.filter {
            $0.quality == .enhanced
        }.sorted { $0.displayName < $1.displayName }
    }
    
    private func setDefaultVoice() {
        // Try to find a high-quality English voice
        if let premiumEnglish = premiumVoices.first(where: { $0.language.hasPrefix("en") }) {
            currentVoice = premiumEnglish.voice
        } else if let standardEnglish = englishVoices.first {
            currentVoice = standardEnglish.voice
        } else {
            currentVoice = AVSpeechSynthesisVoice(language: "en-US")
        }
    }
    
    // MARK: - Voice Selection
    
    func setVoice(_ voiceOption: VoiceOption) {
        currentVoice = voiceOption.voice
    }
    
    func setVoiceByIdentifier(_ identifier: String) {
        if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            currentVoice = voice
        }
    }
    
    func getCurrentVoice() -> VoiceOption? {
        guard let voice = currentVoice else { return nil }
        return VoiceOption(voice: voice)
    }
    
    // MARK: - Speech Control
    
    func speak(text: String) {
        let utterance = createUtterance(from: text)
        synthesizer.speak(utterance)
    }
    
    func speakChapter(_ chapter: Chapter) {
        let fullText = "\(chapter.title). \(chapter.content)"
        speak(text: fullText)
    }
    
    func speakDocument(_ document: EbookDocument) {
        let fullText = document.chapters.map { chapter in
            "\(chapter.title). \(chapter.content)"
        }.joined(separator: ". Next chapter. ")

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
    
    func pauseSpeaking() {
        synthesizer.pauseSpeaking(at: .word)
    }
    
    func continueSpeaking() {
        synthesizer.continueSpeaking()
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Speech Settings
    
    func setSpeechRate(_ rate: Float) {
        speechRate = max(AVSpeechUtteranceMinimumSpeechRate, 
                        min(AVSpeechUtteranceMaximumSpeechRate, rate))
    }
    
    func setSpeechPitch(_ pitch: Float) {
        speechPitch = max(0.5, min(2.0, pitch))
    }
    
    func setSpeechVolume(_ volume: Float) {
        speechVolume = max(0.0, min(1.0, volume))
    }
    
    // MARK: - Utility Functions
    
    var isSpeaking: Bool {
        return synthesizer.isSpeaking
    }
    
    var isPaused: Bool {
        return synthesizer.isPaused
    }
    
    func getRecommendedVoices() -> [VoiceOption] {
        // Return the best voices for audiobook reading
        let recommendedIdentifiers = [
            "com.apple.ttsbundle.Samantha-compact",  // Classic female
            "com.apple.ttsbundle.Alex-compact",      // Classic male
            "com.apple.ttsbundle.siri_female_en-US_compact", // Siri female
            "com.apple.ttsbundle.siri_male_en-US_compact"    // Siri male
        ]
        
        var recommended: [VoiceOption] = []
        
        for identifier in recommendedIdentifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                recommended.append(VoiceOption(voice: voice))
            }
        }
        
        // If we don't have the specific voices, return premium English voices
        if recommended.isEmpty {
            return Array(premiumVoices.prefix(4))
        }
        
        return recommended
    }
    
    func getVoicesByLanguage() -> [String: [VoiceOption]] {
        var voicesByLanguage: [String: [VoiceOption]] = [:]
        
        for voiceOption in availableVoices {
            let languageCode = String(voiceOption.language.prefix(2))
            if voicesByLanguage[languageCode] == nil {
                voicesByLanguage[languageCode] = []
            }
            voicesByLanguage[languageCode]?.append(voiceOption)
        }
        
        return voicesByLanguage
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeech: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        delegate?.speechDidStart()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        delegate?.speechDidFinish()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        delegate?.speechDidPause()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        delegate?.speechDidContinue()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        delegate?.speechProgress(range: characterRange, utterance: utterance)
    }
}