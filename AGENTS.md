# Repository Guidelines

## Project Structure & Module Organization
- Entry points and app lifecycle live in `ClipPilot/Sources/App`, with clipboard/core services in `Sources/Core` and shared models in `Sources/Models`.
- UI and menu bar code sits in `Sources/Views`; reuse shared helpers in `Sources/Utilities`.
- Assets/localization and bundled resources are under `Sources/Resources` (declared in `Package.swift`).
- Tests reside in `ClipPilot/Tests/ClipPilotTests`; add new suites beside the code they cover when possible.

## Build, Test, and Development Commands
- SwiftPM (fast local loop):
  - `cd ClipPilot && swift build` — debug build.
  - `cd ClipPilot && swift test` — run XCTest suite.
- Xcode:
  - Open `ClipPilot/Package.swift` or the workspace, select `ClipPilot` scheme, ⌘R to run, ⌘B to build.
  - For release artifacts: `xcodebuild -scheme ClipPilot -configuration Release archive -archivePath build/ClipPilot.xcarchive`.

## Coding Style & Naming Conventions
- Target Swift 5.9+, macOS 13+, Xcode 15; prefer SPM-friendly code (no hard absolute paths).
- Indent with 4 spaces; keep lines focused and avoid trailing whitespace; include a trailing newline.
- Naming: `PascalCase` for types/protocols, `lowerCamelCase` for vars/functions, concise enum cases, `static let` for shared constants.
- Keep side effects in Core/Utilities; Views should stay UI-focused. Use dependency injection for services where practical.
- Document non-obvious behavior with `///` doc comments and add brief guard/early-return comments only when intent is not clear from code.

## Testing Guidelines
- XCTest is the default; place new tests in `Tests/ClipPilotTests` and mirror source folder names when adding new files.
- Prefer deterministic tests: inject stub preferences/history stores instead of relying on the real pasteboard.
- Run `swift test` before opening a PR; include failing seeds or sample inputs in test names (e.g., `testAddItem_skipsDuplicateText`).

## Commit & Pull Request Guidelines
- Use clear, imperative commits (e.g., `Add pasteboard polling backoff`, `Fix image size limit check`). Squash locally if a change is noisy.
- PRs should include: a short summary, screenshots for UI changes, steps to reproduce/verify, and linked issues if applicable.
- Note any permissions/UI flows touched (Accessibility prompts, login item toggle) and list the tests you ran (`swift test`, manual scenarios).

## Release Packaging (DMG)

### Automated Build (Recommended)
The project includes automated scripts for creating distribution-ready DMG files:

1. **Generate app icon and DMG background:**
   ```bash
   ./scripts/create-icons.sh
   ```
   This creates `ClipPilot/Resources/AppIcon.icns` and DMG background images in `dmg-resources/`.

2. **Build DMG with automated script:**
   ```bash
   ./scripts/build-dmg.sh
   ```
   This script:
   - Builds release version with Swift Package Manager
   - Creates .app bundle with proper Info.plist
   - Code signs with entitlements and Hardened Runtime
   - Creates DMG with custom background and layout
   - Output: `ClipPilot-{version}.dmg`

### Manual Build Process (Advanced)
- Release archive: `cd ClipPilot && xcodebuild -scheme ClipPilot -configuration Release archive -archivePath build/ClipPilot.xcarchive`.
- Export app: create `exportOptions.plist` for your team, then run `xcodebuild -exportArchive -archivePath build/ClipPilot.xcarchive -exportPath build -exportOptionsPlist exportOptions.plist` to get `build/ClipPilot.app`.
- Create DMG: `hdiutil create -volname "ClipPilot" -srcfolder build/ClipPilot.app -ov -format UDZO build/ClipPilot.dmg`.
- (Optional) Notarize and staple if distributing publicly; mount the DMG and launch once to confirm gatekeeper prompts and Accessibility flow.

## Security & Configuration Tips
- Respect user privacy: keep exclusions and size limits in `Preferences.shared`; avoid logging sensitive clipboard contents.
- Update `entitlements.plist` and `Info.plist` intentionally; do not add new capabilities without justification.
- When altering hotkeys or background behavior, ensure Accessibility and Login Item flows remain documented and tested manually.
