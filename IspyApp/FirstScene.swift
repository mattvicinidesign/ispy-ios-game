import SpriteKit

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Level 1 layout (tune `nRect` after locking final `scene_01` art)

/// Normalized hit box: origin **bottom-left** of the image, 0…1 in each axis (matches math below).
private struct Level1Target {
    let clue: String
    let nRect: CGRect
}

private let level1Name = "The Morning Room"
private let level1Targets: [Level1Target] = [
    Level1Target(
        clue: "I spy something soft you can sit on.",
        nRect: CGRect(x: 0.06, y: 0.14, width: 0.26, height: 0.34)
    ),
    Level1Target(
        clue: "I spy something that tells the time.",
        nRect: CGRect(x: 0.38, y: 0.52, width: 0.18, height: 0.22)
    ),
    Level1Target(
        clue: "I spy something green and growing.",
        nRect: CGRect(x: 0.62, y: 0.20, width: 0.22, height: 0.30)
    ),
    Level1Target(
        clue: "I spy something with pages to turn.",
        nRect: CGRect(x: 0.72, y: 0.55, width: 0.20, height: 0.18)
    ),
]

// MARK: - Scene

final class FirstScene: SKScene {

    /// Holds the artwork; scaled & moved for zoom / pan.
    private let worldNode = SKNode()
    private var backgroundNode: SKSpriteNode!

    private var pinchGesture: UIPinchGestureRecognizer?
    private var panGesture: UIPanGestureRecognizer?
    private var pinchStartScale: CGFloat = 1
    private var lastPanTranslation: CGPoint = .zero

    private var zoomScale: CGFloat = 1
    private let minZoom: CGFloat = 1
    private let maxZoom: CGFloat = 4

    private var hudBar: SKShapeNode!
    private var clueLabels: [SKLabelNode] = []
    private var titleLabel: SKLabelNode!
    private var backButton: SKShapeNode!
    private var backLabel: SKLabelNode!

    private var foundFlags: [Bool] = []
    private var isComplete = false

    private var winOverlay: SKNode?
    private var winDismissButton: SKShapeNode?

    /// Scene Y above this is the artwork (below is HUD); used to avoid stealing pans from the clue strip.
    private var gameplayHudTop: CGFloat = 0

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = .zero
        foundFlags = Array(repeating: false, count: level1Targets.count)

        setupBackground()
        addChild(worldNode)
        setupHUD()
        setupBackButton()
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

    // MARK: Setup

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

    private func attachGestures(to view: SKView) {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        view.addGestureRecognizer(pinch)
        pinchGesture = pinch

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 2
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
        if let pinchGesture {
            view.removeGestureRecognizer(pinchGesture)
        }
        if let panGesture {
            view.removeGestureRecognizer(panGesture)
        }
        pinchGesture = nil
        panGesture = nil
    }

    @objc private func handlePinch(_ gr: UIPinchGestureRecognizer) {
        guard !isComplete, let view else { return }

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
        guard !isComplete, let view else { return }

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

    /// Keeps the scaled sprite from drifting past edges; when the image is larger than the screen, allows pan across the full range.
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

    private func setupHUD() {
        let bar = SKShapeNode()
        bar.fillColor = SKColor(white: 0.05, alpha: 0.82)
        bar.strokeColor = .clear
        bar.zPosition = 50
        bar.name = "hud"
        addChild(bar)
        hudBar = bar

        let t = SKLabelNode(text: level1Name.uppercased())
        t.fontName = "AvenirNext-DemiBold"
        t.fontSize = 13
        t.fontColor = SKColor(white: 0.75, alpha: 1)
        t.horizontalAlignmentMode = .center
        t.verticalAlignmentMode = .center
        t.zPosition = 51
        addChild(t)
        titleLabel = t

        clueLabels = level1Targets.map { def in
            let l = SKLabelNode(text: "○  \(def.clue)")
            l.fontName = "AvenirNext-Regular"
            l.fontSize = 15
            l.fontColor = .white
            l.horizontalAlignmentMode = .left
            l.verticalAlignmentMode = .center
            l.numberOfLines = 0
            l.preferredMaxLayoutWidth = size.width - 48
            l.zPosition = 51
            addChild(l)
            return l
        }
    }

    private func setupBackButton() {
        let btn = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 8)
        btn.fillColor = SKColor(white: 0.2, alpha: 0.9)
        btn.strokeColor = SKColor.white.withAlphaComponent(0.35)
        btn.lineWidth = 1
        btn.zPosition = 60
        btn.name = "back"
        addChild(btn)
        backButton = btn

        let lbl = SKLabelNode(text: "← Menu")
        lbl.fontName = "AvenirNext-DemiBold"
        lbl.fontSize = 16
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        lbl.horizontalAlignmentMode = .center
        lbl.zPosition = 61
        addChild(lbl)
        backLabel = lbl
    }

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

        let hudHeight: CGFloat = min(200, size.height * 0.28)
        gameplayHudTop = hudHeight
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: size.width, height: hudHeight))
        hudBar.path = path
        hudBar.position = .zero

        titleLabel.position = CGPoint(x: size.width / 2, y: hudHeight - 18)

        let leftX: CGFloat = 24
        var y = hudHeight - 44
        for label in clueLabels {
            label.position = CGPoint(x: leftX, y: y)
            label.preferredMaxLayoutWidth = size.width - 48
            y -= 22
        }

        backButton.position = CGPoint(x: 58, y: size.height - 36)
        backLabel.position = CGPoint(x: 58, y: size.height - 36)

        layoutWinOverlayIfNeeded()
    }

    // MARK: Input

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let p = touch.location(in: self)

        if isComplete, let btn = winDismissButton {
            let inBtn = touch.location(in: btn)
            if btn.contains(inBtn) {
                returnToMenu()
                return
            }
            return
        }

        let inBack = touch.location(in: backButton)
        if backButton.contains(inBack) {
            returnToMenu()
            return
        }

        let hudTop = hudBar.path?.boundingBox.height ?? 0
        if p.y <= hudTop { return }

        guard let bg = backgroundNode,
              let texture = bg.texture,
              texture.size().width > 0,
              texture.size().height > 0 else { return }

        let local = touch.location(in: bg)
        let w = bg.size.width
        let h = bg.size.height
        let u = (local.x + w / 2) / w
        let v = (local.y + h / 2) / h

        guard u >= 0, u <= 1, v >= 0, v <= 1 else {
            wrongTap(at: p)
            return
        }

        for i in level1Targets.indices where !foundFlags[i] {
            let r = level1Targets[i].nRect
            if u >= r.minX, u <= r.maxX, v >= r.minY, v <= r.maxY {
                markFound(index: i, at: p)
                return
            }
        }

        wrongTap(at: p)
    }

    private func markFound(index: Int, at scenePoint: CGPoint) {
        foundFlags[index] = true
        refreshClues()
        correctRipple(at: scenePoint)
        if !foundFlags.contains(false) {
            showWinOverlay()
        }
    }

    private func refreshClues() {
        for i in clueLabels.indices {
            let prefix = foundFlags[i] ? "✓  " : "○  "
            clueLabels[i].text = "\(prefix)\(level1Targets[i].clue)"
            clueLabels[i].fontColor = foundFlags[i]
                ? SKColor(red: 0.5, green: 0.95, blue: 0.55, alpha: 1)
                : .white
        }
    }

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

    private func wrongTap(at point: CGPoint) {
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

    // MARK: Win + navigation

    private func showWinOverlay() {
        isComplete = true

        let root = SKNode()
        root.zPosition = 200
        addChild(root)
        winOverlay = root

        let dim = SKSpriteNode(color: SKColor(white: 0, alpha: 0.55), size: size)
        dim.anchorPoint = CGPoint(x: 0, y: 0)
        dim.position = .zero
        root.addChild(dim)

        let msg = SKLabelNode(text: "You found them all!")
        msg.fontName = "AvenirNext-Bold"
        msg.fontSize = 28
        msg.fontColor = .white
        msg.position = CGPoint(x: size.width / 2, y: size.height / 2 + 24)
        root.addChild(msg)

        let sub = SKLabelNode(text: level1Name)
        sub.fontName = "AvenirNext-Regular"
        sub.fontSize = 17
        sub.fontColor = SKColor(white: 0.85, alpha: 1)
        sub.position = CGPoint(x: size.width / 2, y: size.height / 2 - 8)
        root.addChild(sub)

        let btn = SKShapeNode(rectOf: CGSize(width: 220, height: 52), cornerRadius: 14)
        btn.fillColor = SKColor(white: 0.22, alpha: 1)
        btn.strokeColor = SKColor.white.withAlphaComponent(0.45)
        btn.lineWidth = 2
        btn.position = CGPoint(x: size.width / 2, y: size.height / 2 - 72)
        btn.name = "winOk"
        root.addChild(btn)
        winDismissButton = btn

        let btnLabel = SKLabelNode(text: "Back to menu")
        btnLabel.fontName = "AvenirNext-DemiBold"
        btnLabel.fontSize = 18
        btnLabel.fontColor = .white
        btnLabel.verticalAlignmentMode = .center
        btnLabel.position = btn.position
        btnLabel.zPosition = 1
        root.addChild(btnLabel)
    }

    private func layoutWinOverlayIfNeeded() {
        guard let root = winOverlay else { return }
        root.children.forEach { child in
            if let s = child as? SKSpriteNode, s.color == SKColor(white: 0, alpha: 0.55) {
                s.size = size
            }
        }
        for child in root.children {
            guard let label = child as? SKLabelNode else { continue }
            if label.text == "You found them all!" {
                label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 24)
            } else if label.text == level1Name {
                label.position = CGPoint(x: size.width / 2, y: size.height / 2 - 8)
            } else if label.text == "Back to menu" {
                label.position = CGPoint(x: size.width / 2, y: size.height / 2 - 72)
            }
        }
        winDismissButton?.position = CGPoint(x: size.width / 2, y: size.height / 2 - 72)
    }

    private func returnToMenu() {
        detachGestures(from: view)
        let menu = MenuScene(size: size)
        menu.scaleMode = .resizeFill
        view?.presentScene(menu, transition: SKTransition.fade(withDuration: 0.35))
    }
}

// MARK: - Gesture delegate

extension FirstScene: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = panGesture, gestureRecognizer === pan, !isComplete, let skView = view else {
            return true
        }

        let p = pan.location(in: skView)
        let q = convertPoint(fromView: p)
        if q.y <= gameplayHudTop { return false }
        if q.x <= 130, q.y >= size.height - 96 { return false }
        return true
    }
}
