## Piply iOS (SwiftUI) — UI-first MVP

This folder contains a SwiftUI MVVM UI-first implementation backed by a `MockAPIClient`.

### How to run (since this repo didn’t previously contain an iOS project)
1. Open Xcode → **File → New → Project…** → iOS → **App**.
2. Product Name: `Piply`, Interface: **SwiftUI**, Language: **Swift**.
3. Save the project under `ios/Piply/` (so you get `ios/Piply/Piply.xcodeproj`).
4. In Xcode, drag the folders from this repo into your project:
   - `App/`, `Core/`, `Models/`, `DesignSystem/`, `Features/`
5. Set the app entry point to `PiplyApp` (Xcode should pick it up automatically).

If you already have a preferred iOS project structure, you can move these Swift files into it as-is.


