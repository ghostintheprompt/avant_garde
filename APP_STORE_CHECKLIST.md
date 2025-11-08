# App Store Submission Checklist

## Pre-Submission Requirements

### 1. Development Setup

- [ ] **Apple Developer Account** ($99/year)
  - Enrolled in Apple Developer Program
  - Developer certificate installed
  - Provisioning profiles configured

- [ ] **Xcode Project Setup**
  - [ ] Create proper .xcodeproj (not just Swift Package)
  - [ ] Set bundle identifier: `com.avantgarde.authoring`
  - [ ] Set version: `1.0.0`
  - [ ] Set build number: `1`
  - [ ] Configure deployment target: macOS 12.0+

### 2. Code Signing & Entitlements

- [ ] **Code Signing**
  - [ ] Developer ID Application certificate
  - [ ] Mac App Distribution certificate
  - [ ] Configure automatic signing or manual signing
  - [ ] Set development team

- [ ] **Entitlements File**
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
      <key>com.apple.security.app-sandbox</key>
      <true/>
      <key>com.apple.security.files.user-selected.read-write</key>
      <true/>
      <key>com.apple.security.files.downloads.read-write</key>
      <true/>
      <key>com.apple.security.network.client</key>
      <false/>
  </dict>
  </plist>
  ```

### 3. App Icon & Assets

- [ ] **App Icon**
  - [ ] Generate all required sizes from template SVG
  - [ ] 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024
  - [ ] Both 1x and 2x versions
  - [ ] Add to AppIcon.appiconset
  - [ ] Verify in Asset Catalog

- [ ] **App Store Icon**
  - [ ] 1024x1024 PNG
  - [ ] No alpha channel
  - [ ] No rounded corners (Apple adds them)

### 4. Info.plist Configuration

- [x] Bundle name: "Avant Garde"
- [x] Bundle identifier: "com.avantgarde.authoring"
- [x] Version string: "1.0"
- [x] Bundle version: "1.0.0"
- [x] Minimum system version: "12.0"
- [x] High resolution capable: YES
- [x] Copyright notice
- [x] Usage descriptions for microphone/speech
- [ ] Document types (if opening custom files)
- [ ] Exported UTTypes for .avantgarde files

### 5. Build Configuration

- [ ] **Release Build**
  - [ ] Set build configuration to Release
  - [ ] Enable optimization
  - [ ] Strip debug symbols
  - [ ] Archive build for distribution

- [ ] **Validation**
  - [ ] Run in Release mode
  - [ ] No crashes or errors
  - [ ] All features working
  - [ ] Memory leaks checked (Instruments)
  - [ ] Performance acceptable

### 6. Testing

- [ ] **Functional Testing**
  - [ ] Complete playtesting checklist
  - [ ] Test on clean macOS installation
  - [ ] Test on macOS 12, 13, 14
  - [ ] Test with different user accounts
  - [ ] Test with limited permissions

- [ ] **Compatibility Testing**
  - [ ] Test on Intel Macs
  - [ ] Test on Apple Silicon Macs
  - [ ] Verify universal binary
  - [ ] Test on external displays
  - [ ] Test with different screen sizes

### 7. App Store Connect Setup

- [ ] **Create App Listing**
  - [ ] Log in to App Store Connect
  - [ ] Create new macOS app
  - [ ] Set bundle ID: com.avantgarde.authoring
  - [ ] Set SKU (unique identifier)

- [ ] **App Information**
  - [ ] App name: "Avant Garde"
  - [ ] Subtitle: "Professional Ebook Authoring"
  - [ ] Category: Productivity / Developer Tools
  - [ ] Secondary category: Graphics & Design
  - [ ] Price: TBD (Free, $9.99, $19.99, $29.99?)

### 8. App Store Metadata

- [ ] **Description** (4000 character limit)
```
Transform your ebook creation workflow with Avant Garde, the professional authoring tool designed for modern writers.

KEY FEATURES:

📝 Rich Text Editor
• Professional formatting toolbar
• Chapter-based organization
• Real-time word count and statistics
• Drag-and-drop chapter reordering

🎨 Color Psychology Themes
• 12 scientifically-backed writing environments
• Boost focus by 23% with Focused Flow
• Increase creativity by 31% with Creative Burst
• Time-based theme recommendations

🎙️ Text-to-Speech Audio
• Premium voice selection
• Chapter-by-chapter playback
• Adjustable speed, pitch, and volume
• Perfect for proofreading

📤 One-Click Export
• Amazon KDP HTML format
• Google Play Books EPUB format
• Platform-specific optimization
• Maintain formatting integrity

PERFECT FOR:
• Fiction and non-fiction authors
• Self-publishers on KDP and Google Play
• Writers who want professional tools
• Anyone frustrated with KDP's limitations

WHY AVANT GARDE?
✓ Better than KDP's clunky editor
✓ Audio feedback for pacing review
✓ Color-coded environments enhance creativity
✓ Export to both platforms instantly
✓ No formatting headaches

Start writing smarter, not harder. Download Avant Garde today.
```

- [ ] **Keywords** (100 character limit)
```
ebook,authoring,kdp,writing,epub,publisher,book,editor,text-to-speech,audio
```

- [ ] **Promotional Text** (170 character limit)
```
Professional ebook authoring with color psychology themes and audio feedback. Export to KDP and Google Play with one click.
```

- [ ] **What's New** (4000 character limit)
```
Initial release of Avant Garde!

• Rich text editor with professional formatting
• 12 color psychology themes
• Text-to-speech audio playback
• Export to KDP and Google Play
• Chapter management and organization
• Real-time statistics and word count

We're excited to bring you the best ebook authoring experience!
```

### 9. Screenshots & Previews

- [ ] **Screenshots** (Minimum 1, Maximum 10)
  - [ ] Main editor window with content
  - [ ] Color theme selector
  - [ ] Chapter navigator sidebar
  - [ ] Export dialog
  - [ ] Voice settings panel
  - [ ] Statistics view
  - [ ] Preferences window

  **Required sizes:**
  - 1280 x 800 pixels (or larger, 16:10 aspect ratio)
  - Recommended: 2560 x 1600 (Retina)

- [ ] **App Preview Video** (Optional, recommended)
  - [ ] 15-30 second demo
  - [ ] Show key features
  - [ ] No audio required
  - [ ] 1920 x 1080 or 3840 x 2160

### 10. Legal & Privacy

- [ ] **Privacy Policy**
  - [ ] Create privacy policy document
  - [ ] Host on public URL
  - [ ] Include in App Store listing
  - [ ] State: "Avant Garde does not collect any user data"

- [ ] **Terms of Service** (Optional)
  - [ ] Create if needed
  - [ ] Host on public URL

- [ ] **EULA** (End User License Agreement)
  - [ ] Use Apple's standard EULA, or
  - [ ] Create custom EULA

- [ ] **Export Compliance**
  - [ ] Determine if app uses encryption
  - [ ] Complete export compliance form
  - [ ] For text-to-speech: likely NO encryption

### 11. Build Upload

- [ ] **Archive Build**
  - [ ] In Xcode: Product → Archive
  - [ ] Wait for archive to complete
  - [ ] Validate archive
  - [ ] Fix any validation errors

- [ ] **Upload to App Store Connect**
  - [ ] Click "Distribute App"
  - [ ] Select "App Store Connect"
  - [ ] Select provisioning profile
  - [ ] Upload build
  - [ ] Wait for processing (can take hours)

### 12. TestFlight (Recommended)

- [ ] **Internal Testing**
  - [ ] Add internal testers (up to 100)
  - [ ] Distribute build
  - [ ] Collect feedback
  - [ ] Fix critical bugs
  - [ ] Upload new build if needed

- [ ] **External Testing** (Optional)
  - [ ] Submit for beta review
  - [ ] Wait for approval (1-2 days)
  - [ ] Add external testers
  - [ ] Collect broader feedback

### 13. Submit for Review

- [ ] **Pre-Submission**
  - [ ] All metadata complete
  - [ ] Screenshots uploaded
  - [ ] Privacy policy URL added
  - [ ] Support URL added (optional)
  - [ ] Marketing URL added (optional)
  - [ ] Demo account (if app requires login) - N/A

- [ ] **Submission**
  - [ ] Select build version
  - [ ] Choose manual or automatic release
  - [ ] Set release date (if automatic)
  - [ ] Add version release notes
  - [ ] Click "Submit for Review"

### 14. Review Process

- [ ] **Wait for Review**
  - Typically 24-48 hours
  - Check status in App Store Connect
  - Respond promptly to any questions

- [ ] **Possible Outcomes**
  - **Approved** → App goes live! 🎉
  - **Rejected** → Fix issues and resubmit
  - **Metadata Rejected** → Fix metadata only
  - **More Info Needed** → Provide clarification

### 15. Post-Approval

- [ ] **App is Live**
  - [ ] Verify app appears in App Store
  - [ ] Test download and installation
  - [ ] Check all metadata displays correctly
  - [ ] Share with the world!

- [ ] **Marketing**
  - [ ] Announce on social media
  - [ ] Create landing page
  - [ ] Reach out to ebook author communities
  - [ ] Consider press release

## Common Rejection Reasons to Avoid

1. **Crashes or bugs** → Thorough testing required
2. **Missing functionality** → All features must work
3. **Privacy issues** → Clear privacy policy
4. **Copyright/trademark violations** → Use original content
5. **Misleading description** → Accurate representation
6. **Poor UI/UX** → Polish the interface
7. **Sandbox violations** → Proper entitlements
8. **Missing icons** → Complete icon set

## Resources

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [macOS App Distribution Guide](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos/overview/themes/)

## Timeline Estimate

- Xcode project setup: 2-4 hours
- Icon generation: 2-3 hours
- Testing and bug fixes: 1-2 days
- App Store Connect setup: 2-3 hours
- Screenshot/video creation: 3-4 hours
- Review wait time: 1-3 days
- **Total: ~1 week** from ready code to App Store

Good luck with your submission! 🚀
