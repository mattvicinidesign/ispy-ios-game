import SpriteKit
import UIKit

final class GameScene: SKScene {

    // MARK: - Camera / World

    private let cameraNode = SKCameraNode()
    private let worldSize = CGSize(width: 2400, height: 2400)

    private var isSetup = false
    private var zoomScale: CGFloat = 1.0
    private let minZoom: CGFloat = 0.6   // zoomed out
    private let maxZoom: CGFloat = 2.0   // zoomed in

    // MARK: - Touch State

    private var lastTouchPosition: CGPoint?
    private var touchStartPos: CGPoint?
    private var isDragging = false
    private var isPinching = false
    private let dragThreshold: CGFloat = 10
    private weak var pinchRecognizer: UIPinchGestureRecognizer?

    // MARK: - Findables / HUD

    private let findableRadius: CGFloat = 22
    private let tapSlop: CGFloat = 44
    private var hudLabel: SKLabelNode?

    private let items: [(id: String, pos: CGPoint)] = [
        ("apple", CGPoint(x: -600, y:  300)),
        ("key",   CGPoint(x:  500, y: -450)),
        ("star",  CGPoint(x: -200, y: -700)),
        ("coin",  CGPoint(x:  800, y:  650)),
        ("cat",   CGPoint(x:  100, y:  500))
    ]

    private var totalFindables: Int { items.count }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        guard !isSetup else { return }
        isSetup = true

        backgroundColor = GameTokens.Colors.background
        scaleMode = .resizeFill

        setupCamera()
        addWorldDebugGrid()
        spawnFindables()
        addTitle()
        setupHUD()
        updateHUD()
        clampCamera()
        addPinchGesture(to: view)
    }

    override func willMove(from view: SKView) {
        if let pinch = pinchRecognizer {
            view.removeGestureRecognizer(pinch)
        }
        pinchRecognizer = nil
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        // Keep HUD pinned to top-left of the screen relative to the camera
        hudLabel?.position = hudAnchorPosition()
        clampCamera()
    }

    // MARK: - Setup

    private func setupCamera() {
        camera = cameraNode
        addChild(cameraNode)
        cameraNode.position = .zero
        cameraNode.setScale(zoomScale)
    }

    private func spawnFindables() {
        for item in items {
            let node = SKShapeNode(circleOfRadius: findableRadius)
            node.name = "findable:\(item.id)"
            node.position = item.pos
            node.fillColor = .white.withAlphaComponent(0.18)
            node.strokeColor = .white.withAlphaComponent(0.35)
            node.lineWidth = 3
            node.zPosition = 5
            addChild(node)
        }
    }

    private func addTitle() {
        let label = SKLabelNode(text: "I-Spy (drag to pan)")
        label.fontName = GameTokens.Typography.titleFont
        label.fontSize = GameTokens.Typography.titleSize
        label.fontColor = GameTokens.Colors.textPrimary
        label.verticalAlignmentMode = .center
        label.position = .zero
        cameraNode.addChild(label)
    }

    private func setupHUD() {
        let label = SKLabelNode(text: "")
        label.fontName = GameTokens.Typography.titleFont
        label.fontSize = 18
        label.fontColor = GameTokens.Colors.textPrimary
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .top
        label.zPosition = 999
        label.position = hudAnchorPosition()

        cameraNode.addChild(label)
        hudLabel = label
    }

    private func hudAnchorPosition() -> CGPoint {
        CGPoint(
            x: -size.width / 2 + 24,
            y:  size.height / 2 - 24
        )
    }

    // MARK: - HUD / Found State

    private func updateHUD() {
        var foundCount = 0
        enumerateChildNodes(withName: "found:*") { _, _ in
            foundCount += 1
        }
        hudLabel?.text = "Found \(foundCount)/\(totalFindables)"
    }

    /// Returns true if we found something (and marked it as found).
    private func tryFind(at point: CGPoint) -> Bool {
        // Find the closest *not-yet-found* node within tapSlop
        var best: (node: SKShapeNode, id: String, dist2: CGFloat)?
        let slop2 = tapSlop * tapSlop

        enumerateChildNodes(withName: "findable:*") { node, _ in
            guard
                let name = node.name,                     // "findable:apple"
                let shape = node as? SKShapeNode
            else { return }

            let id = name.replacingOccurrences(of: "findable:", with: "")

            let dx = shape.position.x - point.x
            let dy = shape.position.y - point.y
            let d2 = dx*dx + dy*dy

            guard d2 <= slop2 else { return }

            if let currentBest = best {
                if d2 < currentBest.dist2 {
                    best = (shape, id, d2)
                }
            } else {
                best = (shape, id, d2)
            }
        }

        guard let hit = best else {
            print("No findable hit")
            return false
        }

        // Mark as found so it won't be considered in future searches
        hit.node.name = "found:\(hit.id)"
        print("FOUND:", hit.id)

        // Visual feedback
        hit.node.fillColor = .white.withAlphaComponent(0.55)
        hit.node.strokeColor = .white
        hit.node.run(.sequence([
            .scale(to: 1.25, duration: 0.08),
            .scale(to: 1.0, duration: 0.12)
        ]))

        updateHUD()
        return true
    }

    // MARK: - World Debug

    private func addWorldDebugGrid() {
        let border = SKShapeNode(rectOf: worldSize)
        border.strokeColor = .white.withAlphaComponent(0.35)
        border.lineWidth = 6
        border.zPosition = 1
        addChild(border)

        let step: CGFloat = 200
        let halfW = worldSize.width / 2
        let halfH = worldSize.height / 2

        for x in stride(from: -halfW, through: halfW, by: step) {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: -halfH))
            path.addLine(to: CGPoint(x: x, y: halfH))
            let line = SKShapeNode(path: path)
            line.strokeColor = .white.withAlphaComponent(0.12)
            line.lineWidth = 2
            line.zPosition = 0
            addChild(line)
        }

        for y in stride(from: -halfH, through: halfH, by: step) {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -halfW, y: y))
            path.addLine(to: CGPoint(x: halfW, y: y))
            let line = SKShapeNode(path: path)
            line.strokeColor = .white.withAlphaComponent(0.12)
            line.lineWidth = 2
            line.zPosition = 0
            addChild(line)
        }
    }

    // MARK: - Camera Clamp

    private func clampCamera() {
        let halfWorldW = worldSize.width / 2
        let halfWorldH = worldSize.height / 2

        // Visible half-extents in world units at current zoom
        let halfViewW = (size.width / 2) / zoomScale
        let halfViewH = (size.height / 2) / zoomScale

        let minX = -halfWorldW + halfViewW
        let maxX =  halfWorldW - halfViewW
        let minY = -halfWorldH + halfViewH
        let maxY =  halfWorldH - halfViewH

        if minX > maxX { cameraNode.position.x = 0 }
        else { cameraNode.position.x = max(min(cameraNode.position.x, maxX), minX) }

        if minY > maxY { cameraNode.position.y = 0 }
        else { cameraNode.position.y = max(min(cameraNode.position.y, maxY), minY) }
    }

    // MARK: - Touch Handling (Pan + Tap)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isPinching else { return }
        touchStartPos = touches.first?.location(in: self)
        lastTouchPosition = touchStartPos
        isDragging = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isPinching else { return }
        guard
            let touch = touches.first,
            let start = touchStartPos,
            let last = lastTouchPosition
        else { return }

        let current = touch.location(in: self)

        if !isDragging {
            let dx = current.x - start.x
            let dy = current.y - start.y
            if (dx*dx + dy*dy) >= (dragThreshold * dragThreshold) {
                isDragging = true
            } else {
                return
            }
        }

        let delta = CGPoint(x: last.x - current.x, y: last.y - current.y)
        cameraNode.position = CGPoint(
            x: cameraNode.position.x + delta.x,
            y: cameraNode.position.y + delta.y
        )

        clampCamera()
        lastTouchPosition = current
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isPinching else { return }
        guard let touch = touches.first else { return }

        if isDragging {
            resetTouchState()
            return
        }

        let point = touch.location(in: self)
        let didHit = tryFind(at: point)

        if !didHit {
            let dot = SKShapeNode(circleOfRadius: 12)
            dot.fillColor = .white
            dot.strokeColor = .clear
            dot.position = point
            dot.zPosition = 10
            addChild(dot)
            dot.run(.sequence([.fadeOut(withDuration: 0.6), .removeFromParent()]))
        }

        resetTouchState()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetTouchState()
    }

    private func resetTouchState() {
        touchStartPos = nil
        lastTouchPosition = nil
        isDragging = false
    }

    // MARK: - Pinch Zoom

    private func addPinchGesture(to view: SKView) {
        if pinchRecognizer != nil { return }
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinch)
        pinchRecognizer = pinch
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            isPinching = true
            resetTouchState()

        case .changed:
            // Divide to make pinch-out zoom in (feel more natural)
            let proposed = zoomScale / recognizer.scale
            zoomScale = max(min(proposed, maxZoom), minZoom)

            cameraNode.setScale(zoomScale)
            clampCamera()

            recognizer.scale = 1.0

        case .ended, .cancelled, .failed:
            isPinching = false
            resetTouchState()

        default:
            break
        }
    }
}
