# IspyApp — Game architecture

This document describes how rendering, camera, input, and audio work **as of the current codebase**. It is the reference for future changes.

## 1. Entry points and view hierarchy

| Layer | Role |
|-------|------|
| `IspyAppApp` | `@main` SwiftUI `App`; hosts `WindowGroup { ContentView() }`. |
| `ContentView` | Embeds `SpriteView(scene:)`; builds initial `MenuScene` via `makeScene()`. |
| `MenuScene` | First `SKScene`: menu UI, tap “Play Level 1” → `presentScene(GameScene)`. |
| `GameScene` | `artworkSize` **3590×2772**, `scene.size = artworkSize`, `.aspectFill`; `baseScale = 2772 / view.bounds.height`; pan + pinch; `clampCameraX()`. |

There is no UIKit app delegate or storyboard; the app is SwiftUI → `SpriteView` → SpriteKit.

## 2. SwiftUI ↔ SpriteKit connection

- `SpriteView(scene: makeScene())` owns an `SKView` and presents the given `SKScene`.
- `MenuScene()` is created without an explicit size; SpriteKit assigns `scene.size` from the view (typically full screen in points).
- `MenuScene` uses `.resizeFill`. `GameScene` uses **`size = artworkSize` (3590×2772)** and **`.aspectFill`**; HUD uses **`view.bounds`** via `viewSize`.
- `ContentView` uses `.ignoresSafeArea()`; `GameScene` bottom bar uses fixed **`bottomInset`**.

## 3. Scene lifecycle

### `MenuScene`

| Method | Behavior |
|--------|----------|
| `didMove(to:)` | Sets `anchorPoint = (0.5, 0.5)`, `scaleMode = .resizeFill`, clears children, `setupUI()`. |
| `didChangeSize(_:)` | **Destroys all children** and rebuilds UI (full reset on rotation/size change). |
| `update(_:)` | Not overridden. |

### `GameScene`

| Method | Behavior |
|--------|----------|
| Init | `MenuScene` uses `GameScene(size: size)` passing current menu `size`. |
| `didMove(to:)` | Once: `size = artworkSize`, `.aspectFill`, music, camera, background (`size = artworkSize`, scale 1), findables, HUD, `applyDefaultCamera()`, pan + pinch on `SKView`. |
| `willMove(from:)` | Removes pan/pinch recognizers. |
| `didChangeSize(_:)` | Relayout HUD; **`clampCameraX()` only** (does not reset default scale). |
| `update(_:)` | Not overridden (no per-frame game loop). |

## 4. Camera system (`GameScene`)

- **`SKCameraNode`**, center **`(artworkWidth/2, artworkHeight/2)`**.
- **Default scale:** `baseScale = artworkSize.height / view.bounds.height`, `setScale(baseScale)`. Debug: `visibleHeight = view.bounds.height * camera.yScale` ≈ **2772**.
- **Clamp X:** `visibleWidth = view.bounds.width * camera.xScale`, `y` locked to **`artworkSize.height/2`**.
- **Pinch:** `newScale = xScale / gesture.scale`, clamped **`[baseScale×0.5, baseScale]`** (zoom in only past default framing).
- **HUD** on `cameraNode`, laid out with **`viewSize`**.

## 5. Input handling (`GameScene`)

| Path | Behavior |
|------|----------|
| **UIPan** | Horizontal: `x -= translation.x * camera.xScale`; `clampCameraX()`. |
| **Pinch** | As above; simultaneous with pan. |
| **Tap / find** | `touchesEnded` → `tryFind(at:)` when movement small. |
| **Back** | `backButton` in `uiLayer` → `MenuScene`. |

## 6. Audio

| Asset | How it’s used |
|-------|----------------|
| `Tech Ambient Vapor.mp3` | `SKAudioNode` in `didMove`, `autoplayLooped = true`, child of `GameScene` (ambient music). |
| `uiTap.mp3` | `SKAction.playSoundFileNamed` on **every** `touchesBegan` (including drags/pan starts). |

There is no central audio manager, volume control, or mute flag.

## 7. Rendering (`GameScene`)

- **`scaleMode`:** `.aspectFill`, **`size = 3590×2772`**.
- **Background:** `size = artworkSize`, `xScale/yScale = 1`; camera only zooms the view.
- **Findables:** Positions in **3590×2772** coordinates.

## 8. Notes

- **`itemSlots`:** Placeholder UI.
- **MenuScene `didChangeSize`:** Clears all children on resize.

## 9. Source of truth (`GameScene`)

| Concern | Authority |
|---------|-----------|
| Artwork / scene | `artworkSize` (3590×2772), `clampCameraX()` |
| View metrics | `view.bounds` → `viewSize` for HUD |
| Default camera scale | `2772 / view.bounds.height` |

## 10. Safe edits

- **Level:** `items`, `spawnFindables()`, `tryFind()`.
- **HUD:** `setupBottomBarUI()`, `layout*`, `updateHUD()`.
- **Camera:** `applyDefaultCamera()`, `handlePinch`, `handlePan`, `clampCameraX()`.

---

## File index

| File | Purpose |
|------|---------|
| `IspyAppApp.swift` | App entry |
| `ContentView.swift` | SwiftUI + `SpriteView` |
| `MenuScene.swift` | Menu scene |
| `GameScene.swift` | Main gameplay scene |
| `GameTokens.swift` | Shared colors/typography |
| `Assets.xcassets` | `BackgroundSetup` image |
| `Tech Ambient Vapor.mp3`, `uiTap.mp3` | Audio (synchronized group under `IspyApp/`) |
