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

// MARK: - Scene (gameplay rendering only — all UI is SwiftUI)

final class FirstScene: SKScene {

    private let worldNode = SKNode()
    private var backgroundNode: SKSpriteNode!
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
        addChild(worldNode)
        layoutForSize()
        setupDustParticles()
        placeTargetMarker()
        attachGestures(to: view)
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

    private func setupBackground() {
        let bg = SKSpriteNode(imageNamed: "scene_01")
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

        let aspect = texture.size().width / texture.size().height
        let h = size.height
        let w = h * aspect
        bg.size = CGSize(width: w, height: h)

        worldNode.addChild(bg)
        backgroundNode = bg
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
    }

    // MARK: Layout

    private func layoutForSize() {
        guard let bg = backgroundNode else { return }

        if let texture = bg.texture, texture.size().width > 0, texture.size().height > 0 {
            let aspect = texture.size().width / texture.size().height
            let h = size.height
            let w = h * aspect
            bg.size = CGSize(width: w, height: h)
        }

        bg.position = .zero
        worldNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        zoomScale = zoomScale.clamped(to: minZoom...maxZoom)
        worldNode.setScale(zoomScale)
        clampWorldPosition()

        if dustEmitters.isEmpty {
            setupDustParticles()
        } else {
            repositionDustEmitters()
        }
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
