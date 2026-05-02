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
    Level1Target(name: "Sofa",    icon: "sofa.fill",           nRect: CGRect(x: 0.06, y: 0.14, width: 0.26, height: 0.34)),
    Level1Target(name: "Clock",   icon: "clock.fill",          nRect: CGRect(x: 0.38, y: 0.52, width: 0.18, height: 0.22)),
    Level1Target(name: "Plant",   icon: "leaf.fill",           nRect: CGRect(x: 0.62, y: 0.20, width: 0.22, height: 0.30)),
    Level1Target(name: "Book",    icon: "book.fill",           nRect: CGRect(x: 0.72, y: 0.55, width: 0.20, height: 0.18)),
    Level1Target(name: "Lamp",    icon: "lamp.desk.fill",      nRect: CGRect(x: 0.30, y: 0.70, width: 0.12, height: 0.18)),
    Level1Target(name: "Vase",    icon: "vase.2.fill",         nRect: CGRect(x: 0.85, y: 0.30, width: 0.10, height: 0.20)),
    Level1Target(name: "Frame",   icon: "photo.artframe",      nRect: CGRect(x: 0.15, y: 0.65, width: 0.14, height: 0.18)),
    Level1Target(name: "Cup",     icon: "cup.and.saucer.fill", nRect: CGRect(x: 0.50, y: 0.10, width: 0.10, height: 0.12)),
    Level1Target(name: "Candle",  icon: "flame.fill",          nRect: CGRect(x: 0.42, y: 0.38, width: 0.08, height: 0.14)),
    Level1Target(name: "Rug",     icon: "rectangle.fill",      nRect: CGRect(x: 0.20, y: 0.02, width: 0.50, height: 0.10)),
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

    private let gameState: GameState

    init(gameState: GameState) {
        self.gameState = gameState
        super.init(size: .zero)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.08, alpha: 1.0)
        anchorPoint = .zero

        gameState.levelName = level1Name
        gameState.items = level1Targets.enumerated().map { i, t in
            FindableItem(id: i, name: t.name, icon: t.icon)
        }
        gameState.foundFlags = Array(repeating: false, count: level1Targets.count)
        gameState.isComplete = false

        setupBackground()
        setupBulbs()
        setupExtraStringLightBulbs()
        setupCoffeeSteam()
        if showDebugGrid {
            let grid = SKNode()
            grid.name = "debugGrid"
            grid.zPosition = debugGridZPosition
            grid.isUserInteractionEnabled = false
            addChild(grid)
            debugGridNode = grid
        }
        addChild(worldNode)
        layoutForSize()
        setupDustParticles()
        placeTargetMarker()
        attachGestures(to: view)

        // SpriteView may set scene size after didMove; refresh grid once bounds are known.
        DispatchQueue.main.async { [weak self] in
            self?.layoutForSize()
        }
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        detachGestures(from: view)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutForSize()
    }

    private var pendingHintConsumed = false

    override func update(_ currentTime: TimeInterval) {
        if let idx = gameState.hintTargetIndex, !pendingHintConsumed {
            pendingHintConsumed = true
            showHint(for: idx)
        } else if gameState.hintTargetIndex == nil {
            pendingHintConsumed = false
        }
    }

    // MARK: Background

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
        let bg = SKSpriteNode(imageNamed: "ComputerSetup")
        bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bg.zPosition = 0
        bg.name = "background"

        guard let texture = bg.texture,
              texture.size().width > 0,
              texture.size().height > 0 else {
            worldNode.addChild(bg)
            backgroundNode = bg
            return
        }

        bg.size = backgroundDisplaySize(texturePixelSize: texture.size())

        worldNode.addChild(bg)
        backgroundNode = bg
    }

    private func setupBulbs() {
        let yellow = SKSpriteNode(imageNamed: "BulbYellowOn")
        yellow.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        yellow.zPosition = 1
        yellow.name = "bulbYellow"
        worldNode.addChild(yellow)
        bulbNode = yellow
        addBulbBlinkLoop(to: yellow, phaseDelay: randomBulbBlinkPhaseDelay())

        let blue = SKSpriteNode(imageNamed: "BulbBlueOn")
        blue.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        blue.zPosition = 1
        blue.name = "bulbBlue"
        blue.size = CGSize(
            width: bulbSpriteWidth * bulbDisplaySizeScale,
            height: bulbSpriteHeight * bulbDisplaySizeScale
        )
        worldNode.addChild(blue)
        blueBulbNode = blue
        addBulbBlinkLoop(to: blue, phaseDelay: randomBulbBlinkPhaseDelay())
    }

    /// Random start phase so bulbs don’t read as a directional wave; new offsets each scene setup.
    private func randomBulbBlinkPhaseDelay() -> TimeInterval {
        Double.random(in: 0..<bulbBlinkCycleDuration)
    }

    /// `bulbDisplaySizeScale` on the texture’s point size so aspect matches the PNG (avoids warping).
    private func extraStringLightDisplaySize(for node: SKSpriteNode) -> CGSize {
        let s = bulbDisplaySizeScale
        guard let tex = node.texture, tex.size().width > 0, tex.size().height > 0 else {
            return CGSize(width: bulbSpriteWidth * s, height: bulbSpriteHeight * s)
        }
        return CGSize(width: tex.size().width * s, height: tex.size().height * s)
    }

    private func setupExtraStringLightBulbs() {
        extraStringLightBulbNodes.removeAll()
        for spec in extraStringLightBulbSpecs {
            let node = SKSpriteNode(imageNamed: spec.asset)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            node.zPosition = 1
            node.name = "extraStringLight_\(spec.asset)"
            node.size = extraStringLightDisplaySize(for: node)
            worldNode.addChild(node)
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
        let anchor = SKNode()
        anchor.name = "coffeeSteamAnchor"
        anchor.zPosition = 2
        worldNode.addChild(anchor)
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
            anchor.addChild(wisp)
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

        func positionOnBackground(u: CGFloat, v: CGFloat, nudgeX: CGFloat, nudgeY: CGFloat) -> CGPoint {
            let sourceX = computerSetupSourcePixelWidth * u
            let sourceY = computerSetupSourcePixelHeight * v
            return CGPoint(
                x: (sourceX / computerSetupSourcePixelWidth - 0.5) * bg.size.width + nudgeX,
                y: (sourceY / computerSetupSourcePixelHeight - 0.5) * bg.size.height + nudgeY
            )
        }

        bulbNode.position = positionOnBackground(
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
            u: blueBulbNormalizedU,
            v: blueBulbNormalizedV,
            nudgeX: 0,
            nudgeY: 0
        )
        blueBulbNode.size = CGSize(
            width: bulbSpriteWidth * bulbDisplaySizeScale,
            height: bulbSpriteHeight * bulbDisplaySizeScale
        )

        coffeeSteamAnchorNode.position = positionOnBackground(
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

        worldNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        zoomScale = zoomScale.clamped(to: minZoom...maxZoom)
        worldNode.setScale(zoomScale)
        clampWorldPosition()

        layoutExtraStringLightBulbs()

        if dustEmitters.isEmpty {
            setupDustParticles()
        } else {
            repositionDustEmitters()
        }

        rebuildDebugGridIfNeeded()
    }

    private func layoutExtraStringLightBulbs() {
        guard extraStringLightBulbNodes.count == extraStringLightBulbSpecs.count else { return }
        let z = worldNode.xScale
        guard z != 0 else { return }
        for i in extraStringLightBulbSpecs.indices {
            let spec = extraStringLightBulbSpecs[i]
            let sceneX = size.width * spec.u
            let sceneY = size.height * spec.v
            extraStringLightBulbNodes[i].position = CGPoint(
                x: (sceneX - worldNode.position.x) / z + extraStringLightBulbNudgeX + spec.dx,
                y: (sceneY - worldNode.position.y) / z + extraStringLightBulbNudgeY + spec.dy
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

    // MARK: Debug target marker

    private func placeTargetMarker() {
        let marker = SKSpriteNode(imageNamed: "target")
        let scenePoint = CGPoint(x: 309.3, y: 458.0)
        marker.position = CGPoint(
            x: (scenePoint.x - worldNode.position.x) / worldNode.xScale,
            y: (scenePoint.y - worldNode.position.y) / worldNode.yScale
        )
        marker.size = CGSize(width: 100, height: 100)
        marker.zPosition = 10
        worldNode.addChild(marker)
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
        guard !gameState.isComplete, let touch = touches.first else { return }

        guard let bg = backgroundNode,
              let texture = bg.texture,
              texture.size().width > 0,
              texture.size().height > 0 else { return }

        let p = touch.location(in: self)
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
