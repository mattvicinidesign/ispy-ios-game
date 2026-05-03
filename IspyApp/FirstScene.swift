import SpriteKit

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}




// MARK: - Level 1 data

private struct Level1Target {
    let name: String
    let icon: String
    let nRect: CGRect
}




private let level1Name = "The Morning Room"
private let level1Targets: [Level1Target] = [
    Level1Target(name: "Ring", icon: "circle.circle", nRect: CGRect(x: 0.1869, y: 0.9397, width: 0.04, height: 0.04)),
    Level1Target(name: "Gum", icon: "square.fill", nRect: CGRect(x: 0.1126, y: 0.2717, width: 0.04, height: 0.04)),
]

// MARK: - ComputerSetup overlays (bulbs, etc.)
// Scaling recipe for future overlays only: `.cursor/rules/scene-background-overlays.mdc`

/// `ComputerSetup.jpg` pixel dimensions (must match asset).
private let computerSetupSourcePixelWidth: CGFloat = 3590
private let computerSetupSourcePixelHeight: CGFloat = 2772

private let bulbNormalizedU: CGFloat = 0.1036
private let bulbNormalizedV: CGFloat = 0.9185

/// World-space offsets (points); negative x moves left, negative y moves down.
private let bulbPositionNudgeX: CGFloat = -1
private let bulbPositionNudgeY: CGFloat = -2

private let bulbSpriteWidth: CGFloat = 72
private let bulbSpriteHeight: CGFloat = 52
/// Uniform scale on `(72, 52)` — much smaller on screen than raw asset points.
private let bulbDisplaySizeScale: CGFloat = 0.35
private let bulbBlinkCycleDuration: TimeInterval = 3.0

private let blueBulbNormalizedU: CGFloat = 0.0451
private let blueBulbNormalizedV: CGFloat = 0.9328

private let extraStringLightBulbNudgeX: CGFloat = 2
private let extraStringLightBulbNudgeY: CGFloat = 10

/// Per-bulb offsets in world space (added after global nudges). Right = +dx, up = +dy.
private let extraStringLightBulbSpecs: [(asset: String, u: CGFloat, v: CGFloat, dx: CGFloat, dy: CGFloat)] = [
    ("BulbTurquoiseOn", 0.0848, 0.9687, 0, 0),
    ("BulbOrangeOn", 0.1541, 0.9565, 0, 4),
    ("BulbMagentaOn", 0.1781, 0.9127, 0, 0),
    ("BulbBlue2On", 0.2434, 0.9216, 0, 1),
    ("BulbYellow2On", 0.2714, 0.9596, 0, 3),
    ("BulbTurquoise2On", 0.2984, 0.9294, 0, -1),
    ("BulbMagenta2On", 0.3407, 0.9427, 1, 2),
    ("BulbBlue3On", 0.3204, 0.9720, 0, 1),
]

private let coffeeSteamNormalizedU: CGFloat = 0.1431
private let coffeeSteamNormalizedV: CGFloat = 0.3242
private let coffeeSteamAssetName = "coffee_steam"
private let coffeeSteamWispCount = 3
/// Display height for steam sprite in scene units (texture is scaled to this, width keeps aspect).
private let coffeeSteamWispTargetHeight: CGFloat = 70

/// Baked frog plush — closed-eye overlay (`PlushFrogEyesClosed.png` is 196×148).
private let plushFrogEyesClosedNormalizedU: CGFloat = 0.7946
private let plushFrogEyesClosedNormalizedV: CGFloat = 0.7485
private let plushFrogEyesClosedSpriteWidth: CGFloat = 196
private let plushFrogEyesClosedSpriteHeight: CGFloat = 148
private let plushFrogEyesClosedAssetName = "PlushFrogEyesClosed"

/// Keyboard overlay (`LEDKeyboardColorShift`) — static placement for alignment; nudge in world points after normalized u/v.
private let ledKeyboardColorShiftNormalizedU: CGFloat = 0.4883
private let ledKeyboardColorShiftNormalizedV: CGFloat = 0.2001
private let ledKeyboardColorShiftNudgeX: CGFloat = 4
private let ledKeyboardColorShiftNudgeY: CGFloat = -5
private let ledKeyboardColorShiftSpriteWidth: CGFloat = 1469
private let ledKeyboardColorShiftSpriteHeight: CGFloat = 290
private let ledKeyboardColorShiftAssetName = "LEDKeyboardColorShift"
/// Applied after texture-accurate overlay sizing (+10%, −2% trim, +3% size tweak vs base overlay scale; aspect preserved).
private let ledKeyboardColorShiftSizeMultiplier: CGFloat = 1.1 * 0.98 * 1.03
/// Full cycle every 56s: idle, then alpha 0→1 + drift right, then 1→0 + drift back (shimmer passes L→R).
private let ledKeyboardColorShiftShimmerCyclePeriod: TimeInterval = 56
private let ledKeyboardColorShiftShimmerSweepDuration: TimeInterval = 14
private let ledKeyboardColorShiftShimmerPeakAlpha: CGFloat = 1
private let ledKeyboardColorShiftShimmerDriftPoints: CGFloat = 14

/// Code-editor style cursor (`CursorBlink.png` is 10×29); same `bulbDisplaySizeScale` sizing as yellow bulb, texture-sized for aspect.
private let cursorBlinkNormalizedU: CGFloat = 0.4905
private let cursorBlinkNormalizedV: CGFloat = 0.5955
private let cursorBlinkSpriteWidth: CGFloat = 10
private let cursorBlinkSpriteHeight: CGFloat = 29
private let cursorBlinkAssetName = "CursorBlink"

/// Invisible-hit overlay for baked ring (`Ring.png` is 97×86).
private let findableRingNormalizedU: CGFloat = 0.2069
private let findableRingNormalizedV: CGFloat = 0.9597
/// World-space offset after normalized placement (+right, +up); idempotent each `layoutForSize` (base +3/−3 plus fine +1/−1 — no runtime accumulation).
private let findableRingNudgeX: CGFloat = 4
private let findableRingNudgeY: CGFloat = -4
private let findableRingSpriteWidth: CGFloat = 97
private let findableRingSpriteHeight: CGFloat = 86
private let findableRingAssetName = "Ring"
private let findableRingNodeName = "findable_ring"
private let findableRingUserDataId = "ring"
private let findableRingHitAlpha: CGFloat = 0.001

/// Invisible-hit overlay for baked gum (`Gum.png` is 152×80).
private let findableGumNormalizedU: CGFloat = 0.1326
private let findableGumNormalizedV: CGFloat = 0.2917
private let findableGumNudgeX: CGFloat = 1
private let findableGumNudgeY: CGFloat = -3
private let findableGumSpriteWidth: CGFloat = 152
private let findableGumSpriteHeight: CGFloat = 80
private let findableGumAssetName = "Gum"
private let findableGumNodeName = "findable_gum"
private let findableGumUserDataId = "gum"
private let findableGumHitAlpha: CGFloat = 0.001

#if DEBUG
/// **Alignment helper:** set to `false` when done; restore each findable sprite `alpha` to **0.001** (`findableRingHitAlpha` / `findableGumHitAlpha`) and `colorBlendFactor` to **0**.
private let findableDebugShowForAlignment = true
private let findableDebugAlignmentAlpha: CGFloat = 0.6
private let findableDebugAlignmentColorBlend: CGFloat = 0.3
#endif

// MARK: - Debug grid (scene coordinates; design art is 3590×2772)

private let debugGridStep: CGFloat = 50
private let debugGridMajorStep: CGFloat = 250
private let debugGridMinorAlpha: CGFloat = 0.16
private let debugGridMajorAlpha: CGFloat = 0.26
private let debugGridMinorLineWidth: CGFloat = 1.0
private let debugGridMajorLineWidth: CGFloat = 2.0
private let debugGridZPosition: CGFloat = 1000

/// Set to `false` to hide the overlay (50pt minor lines, 250pt majors).
private let showDebugGrid = true

// MARK: - Scene (gameplay rendering only — all UI is SwiftUI)

final class FirstScene: SKScene {

    private let worldNode = SKNode()
    private var backgroundNode: SKSpriteNode!
    private var bulbNode: SKSpriteNode!
    private var blueBulbNode: SKSpriteNode!
    private var extraStringLightBulbNodes: [SKSpriteNode] = []
    private var coffeeSteamAnchorNode: SKNode!
    private var coffeeSteamWisps: [SKSpriteNode] = []
    private var plushFrogEyesClosedNode: SKSpriteNode!
    private var ledKeyboardColorShiftNode: SKSpriteNode!
    private var cursorBlinkNode: SKSpriteNode!
    private var findableRingNode: SKSpriteNode!
    private var findableGumNode: SKSpriteNode!
    private var debugGridNode: SKNode?
    private var debugGridLastBackgroundSize: CGSize = .zero
    private var dustEmitters: [SKEmitterNode] = []

    private var pinchGesture: UIPinchGestureRecognizer?
    private var panGesture: UIPanGestureRecognizer?
    private var pinchStartScale: CGFloat = 1
    private var lastPanTranslation: CGPoint = .zero

    private var zoomScale: CGFloat = 1
    private let minZoom: CGFloat = 1
    private let maxZoom: CGFloat = 4

    /// After the first anchored layout (center or restored camera), later `layoutForSize` passes only clamp scale/position — avoids wiping pan/zoom on the async layout pass.
    private var didApplyCameraAnchorThisScene = false

    /// One-time content setup per scene instance (`didMove` can run more than once on the same scene; avoids duplicate `addChild` / re-init). Resets naturally on a new `FirstScene` (e.g. debug reload).
    private var hasSetupScene = false

    private let gameState: GameState

    init(gameState: GameState) {
        self.gameState = gameState
        super.init(size: .zero)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError() }

    private var findableRingLevelIndex: Int? {
        level1Targets.firstIndex { $0.name == "Ring" }
    }

    private var findableGumLevelIndex: Int? {
        level1Targets.firstIndex { $0.name == "Gum" }
    }

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.08, alpha: 1.0)
        anchorPoint = .zero

        if !hasSetupScene {
            hasSetupScene = true

            gameState.levelName = level1Name
            gameState.items = level1Targets.enumerated().map { i, t in
                FindableItem(id: i, name: t.name, icon: t.icon)
            }
            gameState.foundFlags = Array(repeating: false, count: level1Targets.count)
            gameState.isComplete = false

            setupBackground()
            setupBulbs()
            setupPlushFrogEyesClosedBlinkOverlay()
            setupLEDKeyboardColorShiftOverlay()
            setupCursorBlinkOverlay()
            setupFindableRingOverlay()
            setupFindableGumOverlay()
            setupExtraStringLightBulbs()
            setupCoffeeSteam()
            if showDebugGrid, childNode(withName: "debugGrid") == nil {
                let grid = SKNode()
                grid.name = "debugGrid"
                grid.zPosition = debugGridZPosition
                grid.isUserInteractionEnabled = false
                addChild(grid)
                debugGridNode = grid
            }
            if worldNode.parent == nil {
                addChild(worldNode)
            }
            layoutForSize()
            setupDustParticles()
        } else {
            // A second `didMove` on the same scene (SpriteView lifecycle) can arrive with the final bounds; without this, `didApplyCameraAnchorThisScene` stays true and only clamp runs, so a bad first-pass center survives.
            if gameState.pendingCameraRestoreOnNextLayout == nil {
                didApplyCameraAnchorThisScene = false
            }
            layoutForSize()
        }

        attachGestures(to: view)

        // SpriteView may set scene size after didMove; refresh grid once bounds are known.
        DispatchQueue.main.async { [weak self] in
            self?.layoutForSize()
        }

        lastDebugFindsResetCount = gameState.debugLevelFindsResetCount

        #if DEBUG
        gameState.requestReloadLevelScene = { [weak self] in
            self?.reloadDebugScene()
        }
        #endif
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        #if DEBUG
        gameState.requestReloadLevelScene = nil
        #endif
        detachGestures(from: view)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // When bounds change, only clamping would keep a center computed for the previous size. Re-anchor unless debug reload is restoring pan/zoom. (Orientation-only checks miss cases where `size` was stale vs the SwiftUI view until layout sync.)
        if oldSize.width > 0, oldSize.height > 0,
           gameState.pendingCameraRestoreOnNextLayout == nil {
            let dw = abs(oldSize.width - size.width)
            let dh = abs(oldSize.height - size.height)
            if dw > 0.5 || dh > 0.5 {
                didApplyCameraAnchorThisScene = false
            }
        }
        layoutForSize()
    }

    private var pendingHintConsumed = false
    private var lastDebugFindsResetCount = 0

    override func update(_ currentTime: TimeInterval) {
        if gameState.debugLevelFindsResetCount != lastDebugFindsResetCount {
            lastDebugFindsResetCount = gameState.debugLevelFindsResetCount
            applyDebugFindsResetSideEffects()
        }

        if let idx = gameState.hintTargetIndex, !pendingHintConsumed {
            pendingHintConsumed = true
            showHint(for: idx)
        } else if gameState.hintTargetIndex == nil {
            pendingHintConsumed = false
        }
    }

    // MARK: Background

    private func addToWorldIfNeeded(_ node: SKNode) {
        guard node.parent == nil else { return }
        worldNode.addChild(node)
    }

    private func addToBackgroundIfNeeded(_ node: SKNode) {
        guard node.parent == nil else { return }
        backgroundNode.addChild(node)
    }

    /// Normalized art (u, v) → local position on `bg` (anchor 0.5, 0.5). All room overlays use this space, not scene size.
    private func positionOnBackground(
        bg: SKSpriteNode,
        u: CGFloat,
        v: CGFloat,
        nudgeX: CGFloat,
        nudgeY: CGFloat
    ) -> CGPoint {
        let sourceX = computerSetupSourcePixelWidth * u
        let sourceY = computerSetupSourcePixelHeight * v
        return CGPoint(
            x: (sourceX / computerSetupSourcePixelWidth - 0.5) * bg.size.width + nudgeX,
            y: (sourceY / computerSetupSourcePixelHeight - 0.5) * bg.size.height + nudgeY
        )
    }

    /// Aspect-fill: covers `size` while preserving texture aspect ratio.
    private func backgroundDisplaySize(texturePixelSize: CGSize) -> CGSize {
        guard texturePixelSize.width > 0,
              texturePixelSize.height > 0,
              size.width > 0,
              size.height > 0 else {
            return texturePixelSize
        }
        let scale = max(
            size.width / texturePixelSize.width,
            size.height / texturePixelSize.height
        )
        return CGSize(
            width: texturePixelSize.width * scale,
            height: texturePixelSize.height * scale
        )
    }

    private func setupBackground() {
        if let existing = worldNode.childNode(withName: "background") as? SKSpriteNode {
            backgroundNode = existing
            return
        }

        let bg = SKSpriteNode(imageNamed: "ComputerSetup")
        bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bg.zPosition = 0
        bg.name = "background"

        guard let texture = bg.texture,
              texture.size().width > 0,
              texture.size().height > 0 else {
            addToWorldIfNeeded(bg)
            backgroundNode = bg
            return
        }

        bg.size = backgroundDisplaySize(texturePixelSize: texture.size())

        addToWorldIfNeeded(bg)
        backgroundNode = bg
    }

    private func setupBulbs() {
        if let yellow = backgroundNode.childNode(withName: "bulbYellow") as? SKSpriteNode {
            bulbNode = yellow
        } else {
            let yellow = SKSpriteNode(imageNamed: "BulbYellowOn")
            yellow.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            yellow.zPosition = 1
            yellow.name = "bulbYellow"
            addToBackgroundIfNeeded(yellow)
            bulbNode = yellow
            addBulbBlinkLoop(to: yellow, phaseDelay: randomBulbBlinkPhaseDelay())
        }

        if let blue = backgroundNode.childNode(withName: "bulbBlue") as? SKSpriteNode {
            blueBulbNode = blue
        } else {
            let blue = SKSpriteNode(imageNamed: "BulbBlueOn")
            blue.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            blue.zPosition = 1
            blue.name = "bulbBlue"
            blue.size = CGSize(
                width: bulbSpriteWidth * bulbDisplaySizeScale,
                height: bulbSpriteHeight * bulbDisplaySizeScale
            )
            addToBackgroundIfNeeded(blue)
            blueBulbNode = blue
            addBulbBlinkLoop(to: blue, phaseDelay: randomBulbBlinkPhaseDelay())
        }
    }

    private func setupPlushFrogEyesClosedBlinkOverlay() {
        if let existing = backgroundNode.childNode(withName: "plushFrogEyesClosedBlink") as? SKSpriteNode {
            plushFrogEyesClosedNode = existing
            return
        }
        let node = SKSpriteNode(imageNamed: plushFrogEyesClosedAssetName)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.zPosition = 1
        node.alpha = 0
        node.name = "plushFrogEyesClosedBlink"
        addToBackgroundIfNeeded(node)
        plushFrogEyesClosedNode = node
        addPlushFrogBlinkLoop(to: node)
    }

    /// Randomized blink overlay; chained `SKAction.sequence` per cycle so wait durations are re-rolled each time (`repeatForever` fixes child durations at creation).
    private func addPlushFrogBlinkLoop(to node: SKSpriteNode) {
        weak var weakNode: SKSpriteNode? = node
        func runCycle() {
            guard let n = weakNode else { return }
            let gap = Double.random(in: 2...5)
            let closedHold = Double.random(in: 0.08...0.12)
            let seq = SKAction.sequence([
                SKAction.wait(forDuration: gap),
                SKAction.fadeAlpha(to: 1, duration: 0),
                SKAction.wait(forDuration: closedHold),
                SKAction.fadeAlpha(to: 0, duration: 0),
                SKAction.run { runCycle() },
            ])
            n.run(seq)
        }
        runCycle()
    }

    private func setupLEDKeyboardColorShiftOverlay() {
        if let existing = backgroundNode.childNode(withName: "ledKeyboardColorShift") as? SKSpriteNode {
            ledKeyboardColorShiftNode = existing
            return
        }
        let node = SKSpriteNode(imageNamed: ledKeyboardColorShiftAssetName)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.zPosition = 1
        node.alpha = 0
        node.name = "ledKeyboardColorShift"
        addToBackgroundIfNeeded(node)
        ledKeyboardColorShiftNode = node
        addLEDKeyboardColorShiftShimmerLoop(to: node)
    }

    /// Left→right shimmer: fade 0→peak while drifting +X, then fade peak→0 while returning; repeats every `ledKeyboardColorShiftShimmerCyclePeriod`.
    private func addLEDKeyboardColorShiftShimmerLoop(to node: SKSpriteNode) {
        let sweep = ledKeyboardColorShiftShimmerSweepDuration
        let peak = ledKeyboardColorShiftShimmerPeakAlpha
        let period = ledKeyboardColorShiftShimmerCyclePeriod
        let dx = ledKeyboardColorShiftShimmerDriftPoints
        let idle = max(0, period - 2 * sweep)

        let fadeUp = SKAction.fadeAlpha(to: peak, duration: sweep)
        fadeUp.timingMode = .easeInEaseOut
        let moveRight = SKAction.moveBy(x: dx, y: 0, duration: sweep)
        moveRight.timingMode = .easeInEaseOut
        let sweepOut = SKAction.group([fadeUp, moveRight])

        let fadeDown = SKAction.fadeAlpha(to: 0, duration: sweep)
        fadeDown.timingMode = .easeInEaseOut
        let moveBack = SKAction.moveBy(x: -dx, y: 0, duration: sweep)
        moveBack.timingMode = .easeInEaseOut
        let sweepBack = SKAction.group([fadeDown, moveBack])

        let loop = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.wait(forDuration: idle),
                sweepOut,
                sweepBack,
            ])
        )
        node.run(loop)
    }

    private func setupCursorBlinkOverlay() {
        if let existing = backgroundNode.childNode(withName: "cursorBlink") as? SKSpriteNode {
            cursorBlinkNode = existing
            return
        }
        let node = SKSpriteNode(imageNamed: cursorBlinkAssetName)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.zPosition = 1
        node.alpha = 1
        node.name = "cursorBlink"
        addToBackgroundIfNeeded(node)
        cursorBlinkNode = node
        addCursorBlinkLoop(to: node)
    }

    /// Steady editor-style blink: visible 0.5s, fade out 0.1s, hidden 0.5s, fade in 0.1s (repeat).
    private func addCursorBlinkLoop(to node: SKSpriteNode) {
        let holdVisible: TimeInterval = 0.5
        let fade: TimeInterval = 0.1
        let holdHidden: TimeInterval = 0.5
        let loop = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.wait(forDuration: holdVisible),
                SKAction.fadeAlpha(to: 0, duration: fade),
                SKAction.wait(forDuration: holdHidden),
                SKAction.fadeAlpha(to: 1, duration: fade),
            ])
        )
        node.run(loop)
    }

    private func setupFindableRingOverlay() {
        if let existing = backgroundNode.childNode(withName: findableRingNodeName) as? SKSpriteNode {
            findableRingNode = existing
            return
        }
        let node = SKSpriteNode(imageNamed: findableRingAssetName)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.zPosition = 1
        node.alpha = findableRingHitAlpha
        node.name = findableRingNodeName
        let data = NSMutableDictionary()
        data["id"] = findableRingUserDataId
        node.userData = data
        addToBackgroundIfNeeded(node)
        findableRingNode = node
    }

    private func setupFindableGumOverlay() {
        if let existing = backgroundNode.childNode(withName: findableGumNodeName) as? SKSpriteNode {
            findableGumNode = existing
            return
        }
        let node = SKSpriteNode(imageNamed: findableGumAssetName)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.zPosition = 1
        node.alpha = findableGumHitAlpha
        node.name = findableGumNodeName
        let data = NSMutableDictionary()
        data["id"] = findableGumUserDataId
        node.userData = data
        addToBackgroundIfNeeded(node)
        findableGumNode = node
    }

    private func applyDebugFindsResetSideEffects() {
        findableRingNode.removeAction(forKey: "ringFeedback")
        findableRingNode.setScale(1.0)
        findableGumNode.removeAction(forKey: "gumFeedback")
        findableGumNode.setScale(1.0)
        #if DEBUG
        if findableDebugShowForAlignment {
            applyFindableDebugAlignmentVisibilityIfEnabled()
            findableRingNode.alpha = findableRingHitAlpha
            findableRingNode.colorBlendFactor = 0
            findableRingNode.color = .white
            return
        }
        findableRingNode.alpha = findableRingHitAlpha
        findableGumNode.alpha = findableGumHitAlpha
        findableRingNode.colorBlendFactor = 0
        findableGumNode.colorBlendFactor = 0
        #else
        findableRingNode.alpha = findableRingHitAlpha
        findableGumNode.alpha = findableGumHitAlpha
        #endif
    }

    /// Walks `worldNode` subtree; invokes `body` for each `SKSpriteNode` whose name begins with `findable_`.
    private func visitFindableOverlaySprites(in root: SKNode, body: (SKSpriteNode) -> Void) {
        for child in root.children {
            if let name = child.name, name.hasPrefix("findable_"), let sprite = child as? SKSpriteNode {
                body(sprite)
            }
            visitFindableOverlaySprites(in: child, body: body)
        }
    }

    private func applyFindableDebugAlignmentVisibilityIfEnabled() {
        #if DEBUG
        guard findableDebugShowForAlignment else { return }
        visitFindableOverlaySprites(in: worldNode) { sprite in
            // Ring stays a normal findable (near-invisible hit target); alignment overlay applies to other `findable_*` nodes only (e.g. gum).
            guard sprite.name != findableRingNodeName else { return }
            sprite.alpha = findableDebugAlignmentAlpha
            sprite.color = SKColor(red: 0.25, green: 0.85, blue: 1.0, alpha: 1.0)
            sprite.colorBlendFactor = findableDebugAlignmentColorBlend
        }
        #endif
    }

    #if DEBUG
    /// Isolated debug control: rebuilds this level’s scene without restarting the simulator (`GameState` is preserved; `didMove` reinitializes level flags).
    private func reloadDebugScene() {
        guard let view = self.view else { return }
        gameState.pendingCameraRestoreOnNextLayout = (worldNode.position, zoomScale)
        let newScene = FirstScene(gameState: gameState)
        newScene.size = size
        newScene.scaleMode = scaleMode
        view.presentScene(newScene, transition: SKTransition.fade(withDuration: 0.15))
    }
    #endif

    /// Ring stays visually hidden: no alpha / fade — only a brief uniform scale pulse (aspect unchanged).
    private func runFindableRingCorrectFeedback(on node: SKSpriteNode) {
        node.removeAction(forKey: "ringFeedback")
        node.alpha = findableRingHitAlpha
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.075),
            SKAction.scale(to: 1.0, duration: 0.075),
        ])
        node.run(pulse, withKey: "ringFeedback")
    }

    private func runFindableGumCorrectFeedback(on node: SKSpriteNode) {
        #if DEBUG
        if findableDebugShowForAlignment { return }
        #endif
        node.removeAction(forKey: "gumFeedback")
        let scalePulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1),
        ])
        let alphaFlash = SKAction.sequence([
            SKAction.fadeAlpha(to: 1, duration: 0.05),
            SKAction.wait(forDuration: 0.1),
            SKAction.fadeAlpha(to: findableGumHitAlpha, duration: 0.05),
        ])
        let feedback = SKAction.group([scalePulse, alphaFlash])
        node.run(feedback, withKey: "gumFeedback")
    }

    /// Random start phase so bulbs don’t read as a directional wave; new offsets each scene setup.
    private func randomBulbBlinkPhaseDelay() -> TimeInterval {
        Double.random(in: 0..<bulbBlinkCycleDuration)
    }

    /// Uniform `bulbDisplaySizeScale` on the loaded texture’s point size — always preserves asset aspect ratio (no stretching).
    private func overlaySpriteDisplaySize(for node: SKSpriteNode, fallbackWidth: CGFloat, fallbackHeight: CGFloat) -> CGSize {
        let s = bulbDisplaySizeScale
        guard let tex = node.texture, tex.size().width > 0, tex.size().height > 0 else {
            return CGSize(width: fallbackWidth * s, height: fallbackHeight * s)
        }
        return CGSize(width: tex.size().width * s, height: tex.size().height * s)
    }

    private func extraStringLightDisplaySize(for node: SKSpriteNode) -> CGSize {
        overlaySpriteDisplaySize(for: node, fallbackWidth: bulbSpriteWidth, fallbackHeight: bulbSpriteHeight)
    }

    private func setupExtraStringLightBulbs() {
        extraStringLightBulbNodes.removeAll()
        var recovered: [SKSpriteNode] = []
        for spec in extraStringLightBulbSpecs {
            guard let n = backgroundNode.childNode(withName: "extraStringLight_\(spec.asset)") as? SKSpriteNode else {
                recovered = []
                break
            }
            recovered.append(n)
        }
        if recovered.count == extraStringLightBulbSpecs.count {
            extraStringLightBulbNodes = recovered
            return
        }

        for spec in extraStringLightBulbSpecs {
            backgroundNode.childNode(withName: "extraStringLight_\(spec.asset)")?.removeFromParent()
        }
        extraStringLightBulbNodes.removeAll()

        for spec in extraStringLightBulbSpecs {
            let node = SKSpriteNode(imageNamed: spec.asset)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            node.zPosition = 1
            node.name = "extraStringLight_\(spec.asset)"
            node.size = extraStringLightDisplaySize(for: node)
            addToBackgroundIfNeeded(node)
            extraStringLightBulbNodes.append(node)
            addBulbBlinkLoop(to: node, phaseDelay: randomBulbBlinkPhaseDelay())
        }
    }

    private func addBulbBlinkLoop(to node: SKSpriteNode, phaseDelay: TimeInterval) {
        let halfCycle = bulbBlinkCycleDuration / 2.0
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: halfCycle)
        fadeOut.timingMode = .easeInEaseOut
        let fadeIn = SKAction.fadeAlpha(to: 1, duration: halfCycle)
        fadeIn.timingMode = .easeInEaseOut
        let loop = SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn]))
        node.run(SKAction.sequence([SKAction.wait(forDuration: phaseDelay), loop]))
    }

    // MARK: Coffee steam

    private func setupCoffeeSteam() {
        if let anchor = backgroundNode.childNode(withName: "coffeeSteamAnchor") {
            var wisps: [SKSpriteNode] = []
            for i in 0..<coffeeSteamWispCount {
                guard let w = anchor.childNode(withName: "coffeeSteamWisp_\(i)") as? SKSpriteNode else {
                    wisps = []
                    break
                }
                wisps.append(w)
            }
            if wisps.count == coffeeSteamWispCount {
                coffeeSteamAnchorNode = anchor
                coffeeSteamWisps = wisps
                return
            }
        }

        backgroundNode.childNode(withName: "coffeeSteamAnchor")?.removeFromParent()
        coffeeSteamWisps.removeAll()

        let anchor = SKNode()
        anchor.name = "coffeeSteamAnchor"
        anchor.zPosition = 2
        addToBackgroundIfNeeded(anchor)
        coffeeSteamAnchorNode = anchor

        for i in 0..<coffeeSteamWispCount {
            let wisp = SKSpriteNode(imageNamed: coffeeSteamAssetName)
            wisp.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            wisp.zPosition = CGFloat(i)
            wisp.name = "coffeeSteamWisp_\(i)"
            wisp.position = CGPoint(
                x: CGFloat.random(in: -8...8),
                y: CGFloat.random(in: -4...4)
            )
            if wisp.parent == nil {
                anchor.addChild(wisp)
            }
            coffeeSteamWisps.append(wisp)

            let stagger = Double(i) * 0.55 + Double.random(in: 0...0.35)
            let loop = makeCoffeeSteamWispLoop(for: wisp)
            if stagger > 0 {
                wisp.run(SKAction.sequence([SKAction.wait(forDuration: stagger), loop]))
            } else {
                wisp.run(loop)
            }
        }
    }

    /// One cycle: rise + drift, fade 0→0.6→0, scale 0.8→1.2; random duration/drift each cycle.
    private func makeCoffeeSteamWispLoop(for wisp: SKSpriteNode) -> SKAction {
        let maxDur: TimeInterval = 3.0
        let oneCycle = SKAction.sequence([
            SKAction.run { [weak wisp] in
                guard let w = wisp else { return }
                let data = NSMutableDictionary()
                let dur = Double.random(in: 2...3)
                let drift = Double.random(in: -10...10)
                let rise = Double.random(in: 40...60)
                data["dur"] = dur
                data["drift"] = drift
                data["rise"] = rise
                let bx = Double.random(in: -8...8)
                let by = Double.random(in: -4...4)
                data["baseX"] = bx
                data["baseY"] = by
                w.userData = data
                w.position = CGPoint(x: bx, y: by)
                w.alpha = 0
                w.setScale(0.8)
            },
            SKAction.customAction(withDuration: maxDur) { node, elapsed in
                guard let w = node as? SKSpriteNode,
                      let data = w.userData,
                      let dur = data["dur"] as? Double,
                      let drift = data["drift"] as? Double,
                      let rise = data["rise"] as? Double,
                      let bx = data["baseX"] as? Double,
                      let by = data["baseY"] as? Double else { return }
                let t = min(1.0, elapsed / dur)
                let eased = t * t * (3.0 - 2.0 * t)
                w.position = CGPoint(
                    x: CGFloat(bx) + CGFloat(drift) * eased,
                    y: CGFloat(by) + CGFloat(rise) * eased
                )
                let peak: CGFloat = 0.6
                let te = t * t * (3.0 - 2.0 * t)
                let a: CGFloat = te < 0.5
                    ? CGFloat(te / 0.5) * peak
                    : CGFloat((1.0 - te) / 0.5) * peak
                w.alpha = a
                w.setScale(0.8 + 0.4 * CGFloat(t))
            },
        ])
        return SKAction.repeatForever(oneCycle)
    }

    // MARK: Gestures

    private func attachGestures(to view: SKView) {
        detachGestures(from: view)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        pinch.cancelsTouchesInView = false
        pinch.delaysTouchesEnded = false
        view.addGestureRecognizer(pinch)
        pinchGesture = pinch

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 2
        pan.cancelsTouchesInView = false
        pan.delaysTouchesEnded = false
        pan.delegate = self
        view.addGestureRecognizer(pan)
        panGesture = pan
    }

    private func detachGestures(from view: SKView?) {
        guard let view else {
            pinchGesture = nil
            panGesture = nil
            return
        }
        if let pinchGesture { view.removeGestureRecognizer(pinchGesture) }
        if let panGesture { view.removeGestureRecognizer(panGesture) }
        pinchGesture = nil
        panGesture = nil
    }

    @objc private func handlePinch(_ gr: UIPinchGestureRecognizer) {
        guard !gameState.isComplete, let view else { return }

        switch gr.state {
        case .began:
            pinchStartScale = zoomScale
        case .changed:
            let newScale = (pinchStartScale * gr.scale).clamped(to: minZoom...maxZoom)
            let anchorView = gr.location(in: view)
            let anchorScene = convertPoint(fromView: anchorView)
            applyZoom(newScale, fixingScenePoint: anchorScene)
        case .ended, .cancelled, .failed:
            pinchStartScale = zoomScale
            gr.scale = 1
        default:
            break
        }
    }

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        guard !gameState.isComplete, let view else { return }

        let t = gr.translation(in: view)
        if gr.state == .changed {
            let dx = t.x - lastPanTranslation.x
            let dy = t.y - lastPanTranslation.y
            lastPanTranslation = t
            worldNode.position.x += dx
            worldNode.position.y -= dy
            clampWorldPosition()
        } else if gr.state == .ended || gr.state == .cancelled || gr.state == .failed {
            lastPanTranslation = .zero
            gr.setTranslation(.zero, in: view)
        }
    }

    // MARK: Zoom / clamp

    private func applyCameraLayoutForCurrentSize() {
        if let pending = gameState.pendingCameraRestoreOnNextLayout {
            gameState.pendingCameraRestoreOnNextLayout = nil
            zoomScale = pending.zoom.clamped(to: minZoom...maxZoom)
            worldNode.setScale(zoomScale)
            worldNode.position = pending.position
            clampWorldPosition()
            didApplyCameraAnchorThisScene = true
            return
        }

        if !didApplyCameraAnchorThisScene {
            worldNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
            zoomScale = zoomScale.clamped(to: minZoom...maxZoom)
            worldNode.setScale(zoomScale)
            clampWorldPosition()
            didApplyCameraAnchorThisScene = true
        } else {
            zoomScale = zoomScale.clamped(to: minZoom...maxZoom)
            worldNode.setScale(zoomScale)
            clampWorldPosition()
        }
    }

    private func applyZoom(_ newScale: CGFloat, fixingScenePoint anchorScene: CGPoint) {
        let oldScale = zoomScale
        guard oldScale > 0 else { return }

        let local = CGPoint(
            x: (anchorScene.x - worldNode.position.x) / oldScale,
            y: (anchorScene.y - worldNode.position.y) / oldScale
        )
        zoomScale = newScale
        worldNode.setScale(zoomScale)
        worldNode.position = CGPoint(
            x: anchorScene.x - local.x * zoomScale,
            y: anchorScene.y - local.y * zoomScale
        )
        clampWorldPosition()
    }

    private func clampWorldPosition() {
        let z = worldNode.xScale
        let halfW = backgroundNode.size.width * z / 2
        let halfH = backgroundNode.size.height * z / 2

        let lowerX = Swift.min(halfW, size.width - halfW)
        let upperX = Swift.max(halfW, size.width - halfW)
        let x = worldNode.position.x.clamped(to: lowerX...upperX)

        let lowerY = Swift.min(halfH, size.height - halfH)
        let upperY = Swift.max(halfH, size.height - halfH)
        let y = worldNode.position.y.clamped(to: lowerY...upperY)

        worldNode.position = CGPoint(x: x, y: y)
        syncDebugGridWithWorld()
    }

    /// Keeps the debug grid locked to the panned/zoomed room (same space as sprite nudges).
    private func syncDebugGridWithWorld() {
        guard showDebugGrid, let grid = debugGridNode else { return }
        grid.position = worldNode.position
        grid.setScale(worldNode.xScale)
    }

    // MARK: Layout

    private func layoutForSize() {
        guard let bg = backgroundNode else { return }

        if let texture = bg.texture, texture.size().width > 0, texture.size().height > 0 {
            bg.size = backgroundDisplaySize(texturePixelSize: texture.size())
        }

        bg.position = .zero

        bulbNode.position = positionOnBackground(
            bg: bg,
            u: bulbNormalizedU,
            v: bulbNormalizedV,
            nudgeX: bulbPositionNudgeX,
            nudgeY: bulbPositionNudgeY
        )
        bulbNode.size = CGSize(
            width: bulbSpriteWidth * bulbDisplaySizeScale,
            height: bulbSpriteHeight * bulbDisplaySizeScale
        )

        blueBulbNode.position = positionOnBackground(
            bg: bg,
            u: blueBulbNormalizedU,
            v: blueBulbNormalizedV,
            nudgeX: 0,
            nudgeY: 0
        )
        blueBulbNode.size = CGSize(
            width: bulbSpriteWidth * bulbDisplaySizeScale,
            height: bulbSpriteHeight * bulbDisplaySizeScale
        )

        plushFrogEyesClosedNode.position = positionOnBackground(
            bg: bg,
            u: plushFrogEyesClosedNormalizedU,
            v: plushFrogEyesClosedNormalizedV,
            nudgeX: 0,
            nudgeY: 0
        )
        plushFrogEyesClosedNode.size = overlaySpriteDisplaySize(
            for: plushFrogEyesClosedNode,
            fallbackWidth: plushFrogEyesClosedSpriteWidth,
            fallbackHeight: plushFrogEyesClosedSpriteHeight
        )

        ledKeyboardColorShiftNode.position = positionOnBackground(
            bg: bg,
            u: ledKeyboardColorShiftNormalizedU,
            v: ledKeyboardColorShiftNormalizedV,
            nudgeX: ledKeyboardColorShiftNudgeX,
            nudgeY: ledKeyboardColorShiftNudgeY
        )
        let kbBase = overlaySpriteDisplaySize(
            for: ledKeyboardColorShiftNode,
            fallbackWidth: ledKeyboardColorShiftSpriteWidth,
            fallbackHeight: ledKeyboardColorShiftSpriteHeight
        )
        let kbMul = ledKeyboardColorShiftSizeMultiplier
        ledKeyboardColorShiftNode.size = CGSize(
            width: kbBase.width * kbMul,
            height: kbBase.height * kbMul
        )

        cursorBlinkNode.position = positionOnBackground(
            bg: bg,
            u: cursorBlinkNormalizedU,
            v: cursorBlinkNormalizedV,
            nudgeX: 0,
            nudgeY: 0
        )
        cursorBlinkNode.size = overlaySpriteDisplaySize(
            for: cursorBlinkNode,
            fallbackWidth: cursorBlinkSpriteWidth,
            fallbackHeight: cursorBlinkSpriteHeight
        )

        findableRingNode.position = positionOnBackground(
            bg: bg,
            u: findableRingNormalizedU,
            v: findableRingNormalizedV,
            nudgeX: findableRingNudgeX,
            nudgeY: findableRingNudgeY
        )
        findableRingNode.size = overlaySpriteDisplaySize(
            for: findableRingNode,
            fallbackWidth: findableRingSpriteWidth,
            fallbackHeight: findableRingSpriteHeight
        )

        findableGumNode.position = positionOnBackground(
            bg: bg,
            u: findableGumNormalizedU,
            v: findableGumNormalizedV,
            nudgeX: findableGumNudgeX,
            nudgeY: findableGumNudgeY
        )
        findableGumNode.size = overlaySpriteDisplaySize(
            for: findableGumNode,
            fallbackWidth: findableGumSpriteWidth,
            fallbackHeight: findableGumSpriteHeight
        )

        coffeeSteamAnchorNode.position = positionOnBackground(
            bg: bg,
            u: coffeeSteamNormalizedU,
            v: coffeeSteamNormalizedV,
            nudgeX: 0,
            nudgeY: 0
        )
        let steamTex = SKTexture(imageNamed: coffeeSteamAssetName)
        if steamTex.size().height > 0, !coffeeSteamWisps.isEmpty {
            let sh = coffeeSteamWispTargetHeight
            let sw = sh * (steamTex.size().width / steamTex.size().height)
            let steamSize = CGSize(width: sw, height: sh)
            for w in coffeeSteamWisps {
                w.size = steamSize
            }
        }

        applyCameraLayoutForCurrentSize()

        layoutExtraStringLightBulbs()

        if dustEmitters.isEmpty {
            setupDustParticles()
        } else {
            repositionDustEmitters()
        }

        rebuildDebugGridIfNeeded()

        applyFindableDebugAlignmentVisibilityIfEnabled()
    }

    private func layoutExtraStringLightBulbs() {
        guard extraStringLightBulbNodes.count == extraStringLightBulbSpecs.count,
              let bg = backgroundNode else { return }
        for i in extraStringLightBulbSpecs.indices {
            let spec = extraStringLightBulbSpecs[i]
            extraStringLightBulbNodes[i].position = positionOnBackground(
                bg: bg,
                u: spec.u,
                v: spec.v,
                nudgeX: extraStringLightBulbNudgeX + spec.dx,
                nudgeY: extraStringLightBulbNudgeY + spec.dy
            )
            extraStringLightBulbNodes[i].size = extraStringLightDisplaySize(for: extraStringLightBulbNodes[i])
        }
    }

    private func rebuildDebugGridIfNeeded() {
        guard showDebugGrid,
              let grid = debugGridNode,
              let bg = backgroundNode,
              bg.size.width > 1,
              bg.size.height > 1 else {
            debugGridNode?.removeAllChildren()
            debugGridLastBackgroundSize = .zero
            return
        }

        let bgSize = bg.size
        let halfW = bgSize.width / 2
        let halfH = bgSize.height / 2
        let step = debugGridStep
        let majorEvery = Int(debugGridMajorStep / debugGridStep)

        let sizeChanged =
            abs(bgSize.width - debugGridLastBackgroundSize.width) > 0.5
            || abs(bgSize.height - debugGridLastBackgroundSize.height) > 0.5

        if sizeChanged {
            debugGridLastBackgroundSize = bgSize
            grid.removeAllChildren()

            func line(from: CGPoint, to: CGPoint, alpha: CGFloat, width: CGFloat) {
                let path = CGMutablePath()
                path.move(to: from)
                path.addLine(to: to)
                let shape = SKShapeNode(path: path)
                shape.strokeColor = SKColor.white.withAlphaComponent(alpha)
                shape.lineWidth = width
                shape.lineCap = .square
                shape.fillColor = .clear
                shape.isAntialiased = true
                shape.isUserInteractionEnabled = false
                grid.addChild(shape)
            }

            // Background-local coords: center = (0,0), same as bulb / nudge space.
            var xi = Int(floor((-halfW) / step))
            let xMax = Int(ceil(halfW / step))
            while xi <= xMax {
                let x = CGFloat(xi) * step
                let major = xi % majorEvery == 0
                line(
                    from: CGPoint(x: x, y: -halfH),
                    to: CGPoint(x: x, y: halfH),
                    alpha: major ? debugGridMajorAlpha : debugGridMinorAlpha,
                    width: major ? debugGridMajorLineWidth : debugGridMinorLineWidth
                )
                xi += 1
            }

            var yi = Int(floor((-halfH) / step))
            let yMax = Int(ceil(halfH / step))
            while yi <= yMax {
                let y = CGFloat(yi) * step
                let major = yi % majorEvery == 0
                line(
                    from: CGPoint(x: -halfW, y: y),
                    to: CGPoint(x: halfW, y: y),
                    alpha: major ? debugGridMajorAlpha : debugGridMinorAlpha,
                    width: major ? debugGridMajorLineWidth : debugGridMinorLineWidth
                )
                yi += 1
            }
        }

        syncDebugGridWithWorld()
    }

    // MARK: Debug tap coordinates

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let scenePoint = touch.location(in: self)

        if let bg = backgroundNode, bg.size.width > 0, bg.size.height > 0 {
            let local = touch.location(in: bg)
            let u = (local.x + bg.size.width / 2) / bg.size.width
            let v = (local.y + bg.size.height / 2) / bg.size.height
            print(String(format: "Scene: X: %.1f, Y: %.1f  |  Normalized: u: %.4f, v: %.4f", scenePoint.x, scenePoint.y, u, v))
        } else {
            print(String(format: "Scene: X: %.1f, Y: %.1f", scenePoint.x, scenePoint.y))
        }
    }

    // MARK: Tap-to-find (gameplay interaction — stays in SpriteKit)

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let p = touch.location(in: self)

        guard !gameState.isComplete else { return }

        guard let bg = backgroundNode,
              let texture = bg.texture,
              texture.size().width > 0,
              texture.size().height > 0 else { return }

        if let ringIdx = findableRingLevelIndex,
           nodes(at: p).contains(where: { $0.name == findableRingNodeName }) {
            if gameState.foundFlags[ringIdx] { return }
            gameState.foundFlags[ringIdx] = true
            gameState.awardFind()
            if gameState.hintTargetIndex == ringIdx { gameState.hintTargetIndex = nil }
            gameState.updateHUDItemFound(id: findableRingUserDataId)
            runFindableRingCorrectFeedback(on: findableRingNode)
            correctRipple(at: p)
            if !gameState.foundFlags.contains(false) {
                gameState.isComplete = true
                gameState.awardLevelComplete()
            }
            return
        }

        if let gumIdx = findableGumLevelIndex,
           nodes(at: p).contains(where: { $0.name == findableGumNodeName }) {
            if gameState.foundFlags[gumIdx] { return }
            gameState.foundFlags[gumIdx] = true
            gameState.awardFind()
            if gameState.hintTargetIndex == gumIdx { gameState.hintTargetIndex = nil }
            gameState.updateHUDItemFound(id: findableGumUserDataId)
            runFindableGumCorrectFeedback(on: findableGumNode)
            correctRipple(at: p)
            if !gameState.foundFlags.contains(false) {
                gameState.isComplete = true
                gameState.awardLevelComplete()
            }
            return
        }

        let local = touch.location(in: bg)
        let w = bg.size.width
        let h = bg.size.height
        let u = (local.x + w / 2) / w
        let v = (local.y + h / 2) / h

        guard u >= 0, u <= 1, v >= 0, v <= 1 else {
            wrongRipple(at: p)
            return
        }

        for i in level1Targets.indices where !gameState.foundFlags[i] {
            let r = level1Targets[i].nRect
            if u >= r.minX, u <= r.maxX, v >= r.minY, v <= r.maxY {
                gameState.foundFlags[i] = true
                gameState.awardFind()
                if gameState.hintTargetIndex == i { gameState.hintTargetIndex = nil }
                correctRipple(at: p)
                if !gameState.foundFlags.contains(false) {
                    gameState.isComplete = true
                    gameState.awardLevelComplete()
                }
                return
            }
        }

        wrongRipple(at: p)
    }

    // MARK: Hint

    func showHint(for targetIndex: Int) {
        guard targetIndex < level1Targets.count,
              let bg = backgroundNode else { return }

        let target = level1Targets[targetIndex]
        let centerU = target.nRect.midX
        let centerV = target.nRect.midY

        let worldX = (centerU - 0.5) * bg.size.width
        let worldY = (centerV - 0.5) * bg.size.height

        let desiredScale: CGFloat = 2.0
        let newScale = desiredScale.clamped(to: minZoom...maxZoom)

        let targetWorldPos = CGPoint(
            x: size.width / 2 - worldX * newScale,
            y: size.height / 2 - worldY * newScale
        )

        let panAction = SKAction.move(to: targetWorldPos, duration: 0.4)
        panAction.timingMode = .easeInEaseOut

        let scaleAction = SKAction.scale(to: newScale, duration: 0.4)
        scaleAction.timingMode = .easeInEaseOut

        worldNode.run(SKAction.group([panAction, scaleAction])) { [weak self] in
            guard let self else { return }
            self.zoomScale = newScale
            self.clampWorldPosition()

            let sceneX = self.worldNode.position.x + worldX * newScale
            let sceneY = self.worldNode.position.y + worldY * newScale
            self.hintRing(at: CGPoint(x: sceneX, y: sceneY))
        }
    }

    private func hintRing(at point: CGPoint) {
        let ring = SKShapeNode(circleOfRadius: 28)
        ring.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.9)
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.position = point
        ring.zPosition = 50
        ring.setScale(0.5)
        ring.alpha = 0
        addChild(ring)

        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2),
        ])
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.5),
            SKAction.scale(to: 0.9, duration: 0.5),
        ])
        let fadeOut = SKAction.group([
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.scale(to: 1.6, duration: 0.4),
        ])

        ring.run(SKAction.sequence([
            appear,
            SKAction.repeat(pulse, count: 3),
            fadeOut,
            .removeFromParent(),
        ])) { [weak self] in
            self?.gameState.hintTargetIndex = nil
        }
    }

    // MARK: Dust particles

    private static func makeDustTexture(radius: CGFloat, softness: CGFloat) -> SKTexture {
        let full = radius + softness
        let diameter = full * 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        let image = renderer.image { ctx in
            let center = CGPoint(x: full, y: full)
            let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            )!
            ctx.cgContext.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: full,
                options: []
            )
        }
        return SKTexture(image: image)
    }

    private func setupDustParticles() {
        guard dustEmitters.isEmpty else { return }
        guard size.width > 0, size.height > 0 else { return }

        struct Layer {
            let birthRate: CGFloat
            let speed: CGFloat
            let speedRange: CGFloat
            let pScale: CGFloat
            let scaleRange: CGFloat
            let alpha: CGFloat
            let alphaRange: CGFloat
            let wobbleX: CGFloat
            let wobbleDuration: TimeInterval
            let texRadius: CGFloat
            let texSoftness: CGFloat
            let rotSpeed: CGFloat
            let z: CGFloat
        }

        let layers: [Layer] = [
            // Background — smallest, slowest, most faded
            Layer(birthRate: 1.5, speed: 15, speedRange: 5,
                  pScale: 1.0, scaleRange: 0.3,
                  alpha: 0.06, alphaRange: 0.03,
                  wobbleX: 6, wobbleDuration: 3.5,
                  texRadius: 2, texSoftness: 2,
                  rotSpeed: 0.1, z: 1),
            // Mid — main layer
            Layer(birthRate: 2.5, speed: 25, speedRange: 8,
                  pScale: 1.0, scaleRange: 0.4,
                  alpha: 0.10, alphaRange: 0.04,
                  wobbleX: 10, wobbleDuration: 2.8,
                  texRadius: 2.5, texSoftness: 1.5,
                  rotSpeed: 0.2, z: 2),
            // Foreground — slightly larger, a bit more visible
            Layer(birthRate: 1.5, speed: 40, speedRange: 10,
                  pScale: 1.0, scaleRange: 0.3,
                  alpha: 0.14, alphaRange: 0.05,
                  wobbleX: 15, wobbleDuration: 2.2,
                  texRadius: 3, texSoftness: 1,
                  rotSpeed: 0.3, z: 3),
        ]

        for layer in layers {
            let emitter = SKEmitterNode()

            let texDiameter = (layer.texRadius + layer.texSoftness) * 2
            emitter.particleTexture = Self.makeDustTexture(
                radius: layer.texRadius, softness: layer.texSoftness
            )
            emitter.particleSize = CGSize(width: texDiameter, height: texDiameter)

            emitter.particleBirthRate = layer.birthRate
            emitter.numParticlesToEmit = 0

            let fallDistance = size.height + 40
            emitter.particleLifetime = fallDistance / layer.speed + 3
            emitter.particleLifetimeRange = 2

            emitter.emissionAngle = -.pi / 2
            emitter.emissionAngleRange = .pi / 10

            emitter.particleSpeed = layer.speed
            emitter.particleSpeedRange = layer.speedRange

            emitter.particleScale = layer.pScale
            emitter.particleScaleRange = layer.scaleRange

            emitter.particleColor = SKColor(red: 1.0, green: 0.96, blue: 0.88, alpha: 1.0)
            emitter.particleColorBlendFactor = 1.0
            emitter.particleAlpha = layer.alpha
            emitter.particleAlphaRange = layer.alphaRange

            emitter.particleRotationRange = .pi * 2
            emitter.particleRotationSpeed = layer.rotSpeed

            emitter.particleBlendMode = .alpha
            emitter.zPosition = layer.z

            let driftRight = SKAction.moveBy(x: layer.wobbleX, y: 0,
                                             duration: layer.wobbleDuration)
            driftRight.timingMode = .easeInEaseOut
            let driftLeft = SKAction.moveBy(x: -layer.wobbleX, y: 0,
                                            duration: layer.wobbleDuration)
            driftLeft.timingMode = .easeInEaseOut
            emitter.particleAction = SKAction.repeatForever(
                SKAction.sequence([driftRight, driftLeft])
            )

            emitter.position = CGPoint(x: size.width / 2, y: size.height + 20)
            emitter.particlePositionRange = CGVector(dx: size.width + 60, dy: 0)

            addChild(emitter)
            dustEmitters.append(emitter)

            emitter.advanceSimulationTime(TimeInterval(emitter.particleLifetime))
        }
    }

    private func repositionDustEmitters() {
        guard size.width > 0, size.height > 0 else { return }

        for emitter in dustEmitters {
            emitter.position = CGPoint(x: size.width / 2, y: size.height + 20)
            emitter.particlePositionRange = CGVector(dx: size.width + 60, dy: 0)

            if emitter.particleSpeed > 0 {
                emitter.particleLifetime = (size.height + 40) / emitter.particleSpeed + 3
            }
        }
    }

    // MARK: Visual feedback (stays in SpriteKit — these are scene-space effects)

    private func correctRipple(at point: CGPoint) {
        let ring = SKShapeNode(circleOfRadius: 8)
        ring.strokeColor = SKColor(red: 0.4, green: 0.95, blue: 0.5, alpha: 0.95)
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.position = point
        ring.zPosition = 40
        addChild(ring)
        let grow = SKAction.scale(to: 2.8, duration: 0.35)
        let fade = SKAction.fadeOut(withDuration: 0.35)
        ring.run(SKAction.group([grow, fade])) { ring.removeFromParent() }
    }

    private func wrongRipple(at point: CGPoint) {
        let flash = SKShapeNode(circleOfRadius: 6)
        flash.strokeColor = SKColor.white.withAlphaComponent(0.5)
        flash.fillColor = .clear
        flash.lineWidth = 2
        flash.position = point
        flash.zPosition = 40
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 1.4, duration: 0.2),
            ]),
            .removeFromParent(),
        ]))
    }
}

// MARK: - Gesture delegate

extension FirstScene: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gameState.isComplete { return false }
        return true
    }
}
