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
        gameState.clues = level1Targets.map(\.name)
        gameState.items = level1Targets.enumerated().map { i, t in
            FindableItem(id: i, name: t.name, icon: t.icon)
        }
        gameState.foundFlags = Array(repeating: false, count: level1Targets.count)
        gameState.isComplete = false

        setupBackground()
        addChild(worldNode)
        layoutForSize()
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
                correctRipple(at: p)
                if !gameState.foundFlags.contains(false) {
                    gameState.isComplete = true
                }
                return
            }
        }

        wrongRipple(at: p)
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
