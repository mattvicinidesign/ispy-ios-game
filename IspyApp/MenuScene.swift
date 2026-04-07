import SpriteKit

final class MenuScene: SKScene {

    private var playButton: SKShapeNode?

    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(white: 0.08, alpha: 1.0)
        scaleMode = .resizeFill

        removeAllChildren()
        setupUI()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        removeAllChildren()
        setupUI()
    }

    private func setupUI() {
        let title = SKLabelNode(text: "I Spy")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 52
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: 100)
        title.zPosition = 2
        addChild(title)

        let buttonSize = CGSize(width: 320, height: 110)
        let button = SKShapeNode(rectOf: buttonSize, cornerRadius: 18)
        button.name = "playButton"
        button.fillColor = SKColor(white: 0.18, alpha: 1.0)
        button.strokeColor = .white.withAlphaComponent(0.5)
        button.lineWidth = 3
        button.position = .zero
        button.zPosition = 1
        addChild(button)
        playButton = button

        let label = SKLabelNode(text: "Play Level 1")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 34
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 2
        button.addChild(label)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let button = playButton else { return }
        let location = touch.location(in: self)
        guard button.contains(location) else { return }

        let next = GameScene(size: size)
        next.scaleMode = .resizeFill
        let transition = SKTransition.fade(withDuration: 0.3)
        view?.presentScene(next, transition: transition)
    }
}
