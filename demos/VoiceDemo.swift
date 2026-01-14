import Foundation
import AVFoundation

// Demo script to test voice functionality
class VoiceDemo {
    private let textToSpeech = TextToSpeech()
    private let voiceManager = VoiceManager.shared
    
    func runDemo() {
        print("🎙️ Ebook Converter Voice Demo")
        print("=============================\n")
        
        // Show available voices
        showAvailableVoices()
        
        // Show recommended voices for audiobooks
        showRecommendedVoices()
        
        // Show installation instructions
        showInstallationInstructions()
        
        // Test a voice
        testVoice()
    }
    
    private func showAvailableVoices() {
        print("📋 Available Voices:")
        let voices = textToSpeech.availableVoices
        
        for voice in voices.prefix(10) { // Show first 10
            let quality = voice.quality == .enhanced ? "✨ Enhanced" : "📱 Standard"
            print("  • \(voice.displayName) (\(voice.language)) - \(quality)")
        }
        
        if voices.count > 10 {
            print("  ... and \(voices.count - 10) more voices available")
        }
        print()
    }
    
    private func showRecommendedVoices() {
        print("⭐ Best Voices for Audiobooks:")
        let recommended = voiceManager.getBestVoicesForAudiobooks()
        
        if recommended.isEmpty {
            print("  No premium voices found. Consider downloading enhanced voices from System Preferences.")
        } else {
            for voice in recommended {
                print("  🎯 \(voice.displayName) (\(voice.language))")
            }
        }
        print()
    }
    
    private func showInstallationInstructions() {
        print("💡 How to Get More Voices:")
        print("  1. Open System Preferences → Accessibility → Spoken Content")
        print("  2. Click 'System Voice' → 'Customize...'")
        print("  3. Download enhanced voices like:")
        print("     • Samantha (Classic female voice)")
        print("     • Alex (Classic male voice)")
        print("     • Ava (Enhanced female voice)")
        print("     • Tom (Enhanced male voice)")
        print()
    }
    
    private func testVoice() {
        print("🔊 Testing Voice...")
        
        // Use the best available voice
        let recommended = voiceManager.getBestVoicesForAudiobooks()
        if let bestVoice = recommended.first {
            textToSpeech.setVoice(bestVoice)
            print("  Using voice: \(bestVoice.displayName)")
        }
        
        // Test text optimized for audiobook reading
        let testText = "Welcome to your ebook converter! This application can convert between KDP and Google formats, and read your books aloud with natural-sounding voices."
        
        textToSpeech.speak(text: testText)
        print("  🎵 Speaking test text...")
        print("  (The voice should now be reading the test text)")
    }
}

// Usage instructions for authors
print("""
🎧 VOICE SETUP FOR AUTHORS
==========================

Your ebook converter now supports high-quality text-to-speech for audiobook-style reading!

KEY FEATURES:
• Multiple voice options (male/female, different accents)
• Adjustable speed, pitch, and volume
• Chapter-by-chapter reading
• Automatic progression through your entire book
• Pause/resume at any point

RECOMMENDED SETUP:
1. Download enhanced voices from macOS System Preferences
2. Choose voices optimized for long-form reading:
   - Samantha (warm, professional female voice)
   - Alex (clear, authoritative male voice)
   - Ava/Tom (premium enhanced voices if available)

PERFECT FOR:
✓ Proofreading by ear (catch errors you miss reading silently)
✓ Testing pacing and flow of your writing
✓ Accessibility for vision-impaired readers
✓ Multitasking while reviewing your content
✓ Creating audiobook previews

The voice engine automatically handles:
• Chapter transitions
• Proper pronunciation of common words
• Natural pausing at punctuation
• Consistent reading speed

Your KDP ↔ Google conversion workflow is now enhanced with professional-quality audio output!
""")

// Run the demo
let demo = VoiceDemo()
demo.runDemo()
