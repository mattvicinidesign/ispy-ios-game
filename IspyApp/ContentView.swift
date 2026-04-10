import SwiftUI
import SpriteKit

@Observable
private final class GameNav {
    var activeScreen: ActiveScreen = .menu
}

private enum ActiveScreen {
    case menu, level
}

struct ContentView: View {

    @State private var nav = GameNav()

    var body: some View {
        ZStack(alignment: .topLeading) {
            SpriteView(scene: sceneForScreen())
                .ignoresSafeArea()
                .id(nav.activeScreen)

            if nav.activeScreen == .level {
                Button {
                    nav.activeScreen = .menu
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.custom("AvenirNext-DemiBold", size: 17))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.leading, 16)
                .padding(.top, 8)
            }
        }
    }

    private func sceneForScreen() -> SKScene {
        switch nav.activeScreen {
        case .menu:
            let scene = MenuScene()
            scene.scaleMode = .resizeFill
            scene.onStartGame = { [nav] in nav.activeScreen = .level }
            return scene
        case .level:
            let scene = FirstScene()
            scene.scaleMode = .resizeFill
            scene.onRequestMenu = { [nav] in nav.activeScreen = .menu }
            return scene
        }
    }
}

#Preview {
    ContentView()
}
