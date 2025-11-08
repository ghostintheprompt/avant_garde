# Avant Garde - Build & Distribution Guide

## Prerequisites

### Required Software
- **Xcode 14.0+** (for Swift 5.7 support)
- **macOS 12.0+** (Monterey or later)
- **Swift 5.7+**
- **Apple Developer Account** (for App Store distribution)

### Optional Tools
- `librsvg` for converting SVG icon to PNG/ICNS
- `imagemagick` for image processing
- `ffmpeg` for creating app preview videos

---

## Building the App

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/avant-garde.git
cd avant-garde
```

### 2. Build with Swift Package Manager

```bash
# Build in debug mode
swift build

# Build in release mode (optimized)
swift build -c release

# Run the app
swift run
```

### 3. Build with Xcode

```bash
# Open in Xcode
xed .

# Or create an Xcode project
swift package generate-xcodeproj
open AvantGarde.xcodeproj
```

Then build using Xcode:
- Select "AvantGarde" scheme
- Select "My Mac" as destination
- Product → Build (⌘B)
- Product → Run (⌘R) to test

---

## Creating the App Icon

### Convert SVG to ICNS

```bash
cd Resources

# Install librsvg if not already installed
brew install librsvg imagemagick

# Generate PNG files at all required sizes
rsvg-convert -w 16 -h 16 AppIcon.svg > icon_16x16.png
rsvg-convert -w 32 -h 32 AppIcon.svg > icon_16x16@2x.png
rsvg-convert -w 32 -h 32 AppIcon.svg > icon_32x32.png
rsvg-convert -w 64 -h 64 AppIcon.svg > icon_32x32@2x.png
rsvg-convert -w 128 -h 128 AppIcon.svg > icon_128x128.png
rsvg-convert -w 256 -h 256 AppIcon.svg > icon_128x128@2x.png
rsvg-convert -w 256 -h 256 AppIcon.svg > icon_256x256.png
rsvg-convert -w 512 -h 512 AppIcon.svg > icon_256x256@2x.png
rsvg-convert -w 512 -h 512 AppIcon.svg > icon_512x512.png
rsvg-convert -w 1024 -h 1024 AppIcon.svg > icon_512x512@2x.png

# Create iconset directory
mkdir AppIcon.iconset
mv icon_*.png AppIcon.iconset/

# Convert to .icns (macOS icon format)
iconutil -c icns AppIcon.iconset

# Clean up
rm -rf AppIcon.iconset

# The AppIcon.icns file is now ready to use
```

---

## Code Signing & Notarization

### 1. Set Up Code Signing

In Xcode:
1. Select project in navigator
2. Select "AvantGarde" target
3. Go to "Signing & Capabilities"
4. Check "Automatically manage signing"
5. Select your Team
6. Ensure bundle ID matches: `com.avantgarde.authoring`

### 2. Create Archive

```bash
# In Xcode
# Product → Archive

# Or via command line
xcodebuild archive \
  -scheme AvantGarde \
  -archivePath ./build/AvantGarde.xcarchive
```

### 3. Export for Distribution

In Xcode:
1. Window → Organizer
2. Select your archive
3. Click "Distribute App"
4. Choose "Mac App Store Connect"
5. Follow the wizard

Or via command line:

```bash
xcodebuild -exportArchive \
  -archivePath ./build/AvantGarde.xcarchive \
  -exportPath ./build/export \
  -exportOptionsPlist ExportOptions.plist
```

### 4. Notarize the App (for distribution outside App Store)

```bash
# Submit for notarization
xcrun notarytool submit AvantGarde.app.zip \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "TEAMID"

# Check status
xcrun notarytool info <submission-id> \
  --apple-id "your@email.com" \
  --password "app-specific-password"

# Staple the notarization ticket
xcrun stapler staple AvantGarde.app
```

---

## App Store Submission

### 1. Prepare Metadata

Ensure you have:
- [ ] App icon (1024x1024 PNG)
- [ ] 5+ screenshots (see APP_STORE.md)
- [ ] App description and keywords
- [ ] Privacy policy URL
- [ ] Support URL
- [ ] All info in `APP_STORE.md`

### 2. Upload Build

```bash
# Via Xcode
# Product → Archive → Distribute App → Upload

# Or use Transporter app
# Open Transporter.app
# Drag and drop your .ipa or .pkg file
```

### 3. Complete App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Create new version
4. Upload screenshots
5. Fill in description, keywords, etc.
6. Select your uploaded build
7. Submit for review

### 4. Review Process

- Initial review: 1-3 days typically
- Check status in App Store Connect
- Respond to any rejection feedback promptly
- Be ready to provide demo video if requested

---

## Distribution Options

### Option 1: Mac App Store
**Pros:**
- Automatic updates
- Trusted by users
- Built-in payment processing
- Discoverability

**Cons:**
- 30% commission
- Review process
- Sandboxing requirements
- Apple's restrictions

### Option 2: Direct Distribution
**Pros:**
- Keep 100% revenue
- No review process
- More flexibility
- Can offer trials

**Cons:**
- Need to handle payments
- Need to notarize
- Manual update mechanism
- Less trust initially

### Option 3: Both
- Best of both worlds
- Mac App Store for discovery
- Direct for power users
- Can offer different pricing

---

## Testing Checklist

Before submitting, test these scenarios:

### Fresh Install
- [ ] Install on clean Mac (or use VM)
- [ ] Launch app for first time
- [ ] Welcome screen appears
- [ ] Complete onboarding
- [ ] App functions properly

### Core Functionality
- [ ] Create new document
- [ ] Edit text with formatting
- [ ] Add chapters
- [ ] Switch color themes
- [ ] Play audio
- [ ] Export to KDP format
- [ ] Export to Google format
- [ ] Save and open files
- [ ] Preferences work

### Edge Cases
- [ ] Very large documents (1000+ pages)
- [ ] Empty documents
- [ ] Special characters and Unicode
- [ ] Images in documents
- [ ] Rapid theme switching
- [ ] Audio with no text

### System Integration
- [ ] Respects system dark mode
- [ ] Works on multiple displays
- [ ] Survives sleep/wake
- [ ] Survives user switching
- [ ] Memory usage is reasonable
- [ ] CPU usage when idle is low

### Performance
- [ ] App launches in < 3 seconds
- [ ] Theme switching is instant
- [ ] Typing feels responsive
- [ ] No lag with large documents
- [ ] Export completes in reasonable time

---

## Continuous Integration

### GitHub Actions Workflow

Create `.github/workflows/build.yml`:

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Swift
      uses: swift-actions/setup-swift@v1
      with:
        swift-version: '5.7'

    - name: Build
      run: swift build -c release

    - name: Run Tests
      run: swift test
```

---

## Version Management

### Semantic Versioning

Follow [SemVer](https://semver.org/):
- **Major** (1.x.x): Breaking changes
- **Minor** (x.1.x): New features, backward compatible
- **Patch** (x.x.1): Bug fixes

### Update Checklist

When releasing a new version:

1. Update version in `Info.plist`
2. Update `CFBundleVersion` (build number)
3. Update `CHANGELOG.md`
4. Tag release in git: `git tag v1.0.1`
5. Push tag: `git push --tags`
6. Create GitHub release with notes
7. Build and upload to App Store
8. Update website with new version info

---

## Troubleshooting

### Build Fails

```bash
# Clean build
swift package clean
rm -rf .build

# Reset package cache
rm -rf ~/Library/Caches/org.swift.swiftpm
```

### Code Signing Issues

```bash
# Check certificates
security find-identity -v -p codesigning

# Check provisioning profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/
```

### Notarization Fails

- Check code signing is correct
- Ensure hardened runtime is enabled
- Verify entitlements are proper
- Check notarization log for details

---

## Support & Resources

- **Swift Documentation**: https://swift.org/documentation/
- **App Store Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **Xcode Help**: https://developer.apple.com/documentation/xcode
- **Notarization Guide**: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution

---

**Ready to Build?** Start with `swift build` and go from there!
