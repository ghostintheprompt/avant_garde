# Avant Garde App Assets

## App Icon

The app icon (`AppIcon.svg`) features:
- An open book representing ebook authoring
- A quill pen overlay symbolizing professional writing
- Color palette circles indicating the color psychology feature
- Purple gradient background representing creativity and innovation
- Modern, professional design suitable for the Mac App Store

### Converting SVG to macOS App Icon

To convert the SVG to the required .icns format for macOS:

```bash
# Install rsvg-convert if needed (via homebrew)
brew install librsvg

# Generate PNG at various sizes
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

# Convert to .icns
iconutil -c icns AppIcon.iconset

# Clean up
rm -rf AppIcon.iconset
```

### App Store Requirements

For Mac App Store submission, you'll also need:
- 1024x1024 PNG for App Store listing (already provided as SVG at this size)
- Screenshots showing the app in action (at least 3)
- App preview video (optional but recommended)

## Color Scheme

The app uses a consistent color scheme throughout:

### Primary Colors
- **Primary Purple**: `#6366f1` (Indigo-500) - Main brand color
- **Secondary Purple**: `#8b5cf6` (Violet-500) - Accent and gradients
- **Success Green**: `#10b981` (Emerald-500) - Success states
- **Warning Orange**: `#f59e0b` (Amber-500) - Warnings
- **Error Red**: `#ef4444` (Red-500) - Errors

### Neutral Colors
- **Gray 50**: `#f9fafb` - Light backgrounds
- **Gray 100**: `#f3f4f6` - Subtle backgrounds
- **Gray 900**: `#111827` - Dark text
- **White**: `#ffffff` - Pure white backgrounds

## UI Design Principles

1. **Clean and Professional**: Minimal distractions, focus on content
2. **Color Psychology**: Meaningful use of colors based on research
3. **Accessibility**: High contrast ratios, readable fonts
4. **Modern macOS**: Follows Apple's Human Interface Guidelines
5. **Consistent**: Same visual language throughout the app
