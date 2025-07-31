import Foundation
import AVFoundation

class VoiceManager {
    
    static let shared = VoiceManager()
    
    private init() {}
    
    // MARK: - Voice Information
    
    func getAllSystemVoices() -> [VoiceOption] {
        return AVSpeechSynthesisVoice.speechVoices().map { VoiceOption(voice: $0) }
    }
    
    func getHighQualityVoices() -> [VoiceOption] {
        return getAllSystemVoices().filter { $0.quality == .enhanced }
    }
    
    func getVoicesForLanguage(_ languageCode: String) -> [VoiceOption] {
        return getAllSystemVoices().filter { $0.language.hasPrefix(languageCode) }
    }
    
    // MARK: - Voice Recommendations
    
    func getBestVoicesForAudiobooks() -> [VoiceOption] {
        let recommendedIdentifiers = [
            // English voices optimized for long-form reading
            "com.apple.ttsbundle.Samantha-compact",
            "com.apple.ttsbundle.Alex-compact",
            "com.apple.ttsbundle.siri_female_en-US_compact",
            "com.apple.ttsbundle.siri_male_en-US_compact",
            "com.apple.voice.compact.en-US.Zoe",
            "com.apple.voice.compact.en-US.Ava",
            "com.apple.voice.compact.en-US.Tom",
            "com.apple.voice.compact.en-US.Nathan"
        ]
        
        var bestVoices: [VoiceOption] = []
        
        for identifier in recommendedIdentifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                bestVoices.append(VoiceOption(voice: voice))
            }
        }
        
        // If specific voices aren't available, fall back to high-quality English voices
        if bestVoices.isEmpty {
            bestVoices = getHighQualityVoices()
                .filter { $0.language.hasPrefix("en") }
                .prefix(4)
                .map { $0 }
        }
        
        return bestVoices
    }
    
    func getVoiceRecommendations() -> [String: [VoiceOption]] {
        return [
            "Best for Audiobooks": getBestVoicesForAudiobooks(),
            "English Voices": getVoicesForLanguage("en"),
            "High Quality": getHighQualityVoices(),
            "All Voices": getAllSystemVoices()
        ]
    }
    
    // MARK: - Voice Installation Guide
    
    func getVoiceInstallationInstructions() -> String {
        return """
        How to Install Additional Voices on macOS:
        
        1. Open System Preferences (or System Settings on macOS 13+)
        2. Go to Accessibility
        3. Select "Spoken Content" from the sidebar
        4. Click "System Voice" dropdown
        5. Click "Customize..."
        6. Check the boxes for voices you want to download
        7. Click "OK" to download selected voices
        
        Recommended Voices for Audiobooks:
        • English (US) - Samantha (Classic, natural sounding)
        • English (US) - Alex (Male, clear pronunciation)
        • English (US) - Ava (Enhanced, premium quality)
        • English (US) - Tom (Enhanced, professional)
        
        Note: Enhanced voices provide better quality but require more storage space.
        Premium voices may require an internet connection to download.
        """
    }
    
    func getVoiceDownloadLinks() -> [String: String] {
        return [
            "System Preferences": "x-apple.systempreferences:com.apple.preference.speech",
            "Accessibility Settings": "x-apple.systempreferences:com.apple.preference.universalaccess?Spoken_Content"
        ]
    }
    
    // MARK: - Voice Testing
    
    func createVoiceTestSentences() -> [String] {
        return [
            "Welcome to your audiobook experience. This voice will guide you through your literary journey.",
            "Chapter One. It was the best of times, it was the worst of times.",
            "The quick brown fox jumps over the lazy dog. This sentence contains every letter of the alphabet.",
            "In a hole in the ground there lived a hobbit. Not a nasty, dirty, wet hole filled with the ends of worms.",
            "Call me Ishmael. Some years ago, never mind how long precisely, having little or no money in my purse."
        ]
    }
    
    // MARK: - Voice Comparison
    
    func compareVoiceQualities() -> [String: String] {
        return [
            "Standard Quality": "Built-in voices, smaller file size, good for basic text-to-speech",
            "Enhanced Quality": "Downloaded voices, larger file size, more natural pronunciation and intonation",
            "Premium Quality": "Cloud-based voices, require internet, highest quality with natural speech patterns",
            "Compact": "Optimized for mobile devices, balance between quality and storage",
            "High Quality": "Desktop optimized, best offline experience for long-form reading"
        ]
    }
    
    // MARK: - Language Support
    
    func getSupportedLanguages() -> [String: String] {
        let allVoices = getAllSystemVoices()
        var languageMap: [String: String] = [:]
        
        for voice in allVoices {
            let languageCode = String(voice.language.prefix(2))
            let languageName = Locale.current.localizedString(forLanguageCode: languageCode) ?? languageCode
            languageMap[languageCode] = languageName
        }
        
        return languageMap
    }
    
    // MARK: - Performance Optimization
    
    func getOptimalVoiceSettings() -> (rate: Float, pitch: Float, volume: Float) {
        // Optimal settings for audiobook listening
        return (
            rate: 0.45,    // Slightly slower than default for comprehension
            pitch: 1.0,    // Natural pitch
            volume: 0.85   // Comfortable listening level
        )
    }
    
    func getVoicePerformanceInfo(_ voice: VoiceOption) -> String {
        var info = "Voice: \(voice.displayName)\n"
        info += "Language: \(voice.language)\n"
        info += "Quality: \(voice.quality == .enhanced ? "Enhanced" : "Standard")\n"
        
        // Estimate performance characteristics
        if voice.quality == .enhanced {
            info += "Performance: High quality, may use more CPU\n"
            info += "Best for: Long-form reading, audiobooks\n"
        } else {
            info += "Performance: Fast, efficient\n"
            info += "Best for: Quick announcements, basic TTS\n"
        }
        
        return info
    }
}
