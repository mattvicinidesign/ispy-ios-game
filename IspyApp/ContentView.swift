import SwiftUI
import SpriteKit

struct ContentView: View {

    var body: some View {
        SpriteView(scene: makeScene())
            .ignoresSafeArea()
    }

    private func makeScene() -> GameScene {
        let scene = GameScene()
        scene.scaleMode = .resizeFill
        return scene
    }

}

#Preview {
    ContentView()
}
