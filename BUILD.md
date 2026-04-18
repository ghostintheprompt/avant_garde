# Building Avant Garde

Instructions for building the project from source and generating a release DMG.

## Requirements
- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## Clone
```bash
git clone https://github.com/ghostintheprompt/avant_garde.git
cd avant_garde
```

## Build
You can open `AvantGarde.xcodeproj` in Xcode and run the project, or build from the command line:

```bash
swift build
```

## Generate DMG
To create a distributable DMG file, run the included build script:

```bash
./make_dmg.sh
```

The resulting `.dmg` will be in the root directory.

## First Launch
1. Open the `.dmg` file.
2. Drag `AvantGarde.app` to your Applications folder.
3. Right-click the app and select "Open" (since it is an open-source build without developer signing).

## Troubleshooting
- **Missing Dependencies:** The project has zero external dependencies. Ensure your Xcode path is set correctly (`xcode-select -p`).
- **Build Errors:** If the build fails, try cleaning the build directory: `rm -rf build .build`.
- **Silicon/Intel:** The app is built as a Universal binary by default (arm64 + x86_64).
