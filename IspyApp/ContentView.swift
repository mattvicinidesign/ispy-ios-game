import SwiftUI
import SpriteKit

/// Root view: `SpriteView` hosts SpriteKit. Initial scene is `MenuScene` (see `docs/ARCHITECTURE.md`).
struct ContentView: View {

    var body: some View {
        SpriteView(scene: makeScene())
            .ignoresSafeArea()
    }

    private func makeScene() -> MenuScene {
        let scene = MenuScene()
        scene.scaleMode = .resizeFill
        return scene
    }

}

#Preview {
    ContentView()
}
