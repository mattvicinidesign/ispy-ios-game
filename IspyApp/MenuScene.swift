import SpriteKit

/// Bare scene used as the backdrop behind the SwiftUI menu overlay.
final class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(white: 0.08, alpha: 1.0)
        scaleMode = .resizeFill
    }
}
